import json
import os
import re
import sys
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from statistics import median
from typing import Dict, List
from dotenv import load_dotenv
from benchmarking.connect import connect_to_db
from benchmarking.core import (
    RunOutcome,
    TimeBenchmark,
    TimeBenchmarkResult,
    ValueBenchmark,
    ValueBenchmarkResult,
    run_time_benchmark,
    print_time_result,
    run_value_benchmark,
    print_value_result
)
from benchmarking.benchmarks import RUN_PLAN


ZOOM_LEVELS = ["z13", "z17", "z21"]
TABLE_PATTERN = re.compile(r"\b(?:FROM|JOIN)\s+([A-Za-z0-9_.]+)", re.IGNORECASE)


def _get_area_ids(conn, selected_ids=None):
    with conn.cursor() as cur:
        cur.execute("SELECT DISTINCT area_id FROM benchmark.area_poly ORDER BY area_id")
        all_area_ids = [row[0] for row in cur.fetchall()]

        if selected_ids:
            return [aid for aid in selected_ids if aid in all_area_ids]
        return all_area_ids


def _build_length_stats(stat_entries):
    stats = []
    for label, lengths in stat_entries:
        if not lengths:
            continue
        stats.append(
            {
                "label": label,
                "min": min(lengths),
                "median": median(lengths),
                "max": max(lengths),
                "count": len(lengths),
            }
        )
    return stats


def _print_trajectory_stats(stat_entries, sample_size):
    if not stat_entries:
        print("\nNo trajectory statistics available.")
        return []
    stats = _build_length_stats(stat_entries)
    print(f"\n{sample_size} trajectory statistics:")
    for entry in stats:
        print(
            f"{entry['label']}: Min length: {entry['min']}, "
            f"Median length: {entry['median']}, "
            f"Max length: {entry['max']}"
        )
    return stats


def _print_stop_stats(stat_entries, sample_size):
    if not stat_entries:
        print("\nNo stop statistics available.")
        return []
    stats = _build_length_stats(stat_entries)
    print(f"\n{sample_size} stop statistics:")
    for entry in stats:
        print(
            f"{entry['label']}: Min size: {entry['min']}, "
            f"Median size: {entry['median']}, "
            f"Max size: {entry['max']}"
        )
    return stats


def _collect_tables(*sql_statements):
    tables = set()
    for sql in sql_statements:
        if not sql:
            continue
        tables.update(TABLE_PATTERN.findall(sql))
    return sorted(tables)


def _collect_tables_from_benchmark(benchmark):
    if isinstance(benchmark, TimeBenchmark):
        return _collect_tables(benchmark.st_sql, benchmark.cst_sql)
    if isinstance(benchmark, ValueBenchmark):
        return _collect_tables(benchmark.sql)
    return []


def _fetch_random_ids(cur, column_name, table_name, sample_size):
    if sample_size <= 0:
        return []
    if not re.fullmatch(r"[A-Za-z0-9_]+", column_name):
        raise ValueError(f"Invalid column name: {column_name}")
    if not re.fullmatch(r"[A-Za-z0-9_.]+", table_name):
        raise ValueError(f"Invalid table name: {table_name}")
    cur.execute(
        f"SELECT {column_name} FROM {table_name} ORDER BY random() LIMIT %s",
        (sample_size,)
    )
    return [row[0] for row in cur.fetchall()]


def _serialize_run_outcome(run: RunOutcome) -> dict:
    payload = {
        "exec_ms_med": run.exec_ms_med,
        "wall_ms_med": run.wall_ms_med,
        "timed_out": run.timed_out,
    }
    if run.samples:
        payload["samples"] = run.samples
    return payload


def _serialize_time_result(result: TimeBenchmarkResult) -> dict:
    return {
        "st": _serialize_run_outcome(result.st),
        "cst_results": {zoom: _serialize_run_outcome(outcome) for zoom, outcome in result.cst_results.items()},
        "false_positives": result.false_positives,
        "false_negatives": result.false_negatives,
        "per_area_results": {
            str(area_id): {label: _serialize_run_outcome(run) for label, run in runs.items()}
            for area_id, runs in result.per_area_results.items()
        },
    }


def _serialize_value_result(result: ValueBenchmarkResult) -> dict:
    return {"median_values": result.median_values}


def _write_json_report(payload: dict, run_started_at: datetime) -> Path:
    output_dir = Path("benchmarking/benchmark_results")
    output_dir.mkdir(parents=True, exist_ok=True)
    file_name = f"run_{run_started_at.strftime('%Y%m%d_%H%M%S')}.json"
    output_path = output_dir / file_name
    with output_path.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, default=str)
    print(f"\nSaved run report to {output_path}")
    return output_path


def main():
    load_dotenv()
    trajectory_source_table = "prototype2.trajectory_cs"
    stop_source_table = "prototype2.stop_cs"
    trajectory_sample_size = 500
    stop_sample_size = 500

    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        sys.exit("DATABASE_URL not defined in .env file")

    run_started_at = datetime.now(timezone.utc)

    if not RUN_PLAN:
        print("No benchmarks defined in RUN_PLAN. Exiting.")
        return
    conn = connect_to_db()
    try:
        trajectory_ids = []
        stop_ids = []

        traj_linestring_lengths: List[float] = []
        stop_poly_area_size: List[float] = []
        linestring_lengths_by_id: Dict[int, float] = {}
        traj_cellstring_lengths: Dict[str, List[int]] = {zoom: [] for zoom in ZOOM_LEVELS}
        cellstring_lengths: Dict[str, Dict[int, int]] = {zoom: {} for zoom in ZOOM_LEVELS}
        stop_cellstring_lengths: Dict[str, Dict[int, int]] = {zoom: {} for zoom in ZOOM_LEVELS}

        benchmark_outputs = []

        with conn.cursor() as cur:
            trajectory_ids = _fetch_random_ids(
                cur,
                "trajectory_id",
                trajectory_source_table,
                trajectory_sample_size,
            )
            stop_ids = _fetch_random_ids(
                cur,
                "stop_id",
                stop_source_table,
                stop_sample_size,
            )

            if trajectory_ids:
                cur.execute(
                    "SELECT trajectory_id, ST_Length(ST_Transform(geom, 3857)) "
                    "FROM prototype2.trajectory_ls WHERE trajectory_id = ANY(%s)",
                    (trajectory_ids,)
                )
                for traj_id, length in cur.fetchall():
                    if length is None:
                        continue
                    traj_linestring_lengths.append(length)
                    linestring_lengths_by_id[int(traj_id)] = float(length)

                for zoom in ZOOM_LEVELS:
                    cur.execute(
                        f"SELECT trajectory_id, Cardinality(cellstring_{zoom}) "
                        f"FROM {trajectory_source_table} WHERE trajectory_id = ANY(%s)",
                        (trajectory_ids,)
                    )
                    for traj_id, count in cur.fetchall():
                        if count is None:
                            continue
                        traj_cellstring_lengths[zoom].append(count)
                        cellstring_lengths[zoom][int(traj_id)] = int(count)
            if stop_ids:
                cur.execute(
                    "SELECT ST_Area(ST_Transform(geom, 3857)) "
                    "FROM prototype2.stop_poly WHERE stop_id = ANY(%s)",
                    (stop_ids,)
                )
                stop_poly_area_size = [row[0] for row in cur.fetchall() if row[0] is not None]

                for zoom in ZOOM_LEVELS:
                    cur.execute(
                        f"SELECT Cardinality(cellstring_{zoom}) "
                        f"FROM {stop_source_table} WHERE stop_id = ANY(%s)",
                        (stop_ids,)
                    )
                    stop_cellstring_lengths[zoom] = [row[0] for row in cur.fetchall() if row[0] is not None]

        for benchmark in RUN_PLAN:
            bench_instance = benchmark
            if isinstance(bench_instance, TimeBenchmark) and bench_instance.use_area_ids and not bench_instance.area_ids:
                all_area_ids = _get_area_ids(conn)
                bench_instance = replace(bench_instance, area_ids=all_area_ids)

            print(f"\nRunning benchmark:", bench_instance.name)
            tables_used = _collect_tables_from_benchmark(bench_instance)

            if isinstance(bench_instance, TimeBenchmark):
                if bench_instance.with_trajectory_ids:
                    result = run_time_benchmark(conn, bench_instance, trajectory_ids=trajectory_ids)
                elif bench_instance.with_stop_ids:
                    result = run_time_benchmark(conn, bench_instance, stop_ids=stop_ids)
                else:
                    result = run_time_benchmark(conn, bench_instance)
                print_time_result(result)
                benchmark_outputs.append(
                    {
                        "name": bench_instance.name,
                        "benchmark_type": "time",
                        "tables_used": tables_used,
                        "result": _serialize_time_result(result),
                    }
                )
            elif isinstance(bench_instance, ValueBenchmark):
                result = run_value_benchmark(conn, bench_instance, trajectory_ids, stop_ids)
                print_value_result(result)
                benchmark_outputs.append(
                    {
                        "name": bench_instance.name,
                        "benchmark_type": "value",
                        "tables_used": tables_used,
                        "result": _serialize_value_result(result),
                    }
                )

        traj_stats_payload = []
        stop_stats_payload = []

        if traj_linestring_lengths:
            traj_stats_payload.append(("LineString", traj_linestring_lengths))
        for zoom in ZOOM_LEVELS:
            lengths = traj_cellstring_lengths.get(zoom)
            if lengths:
                traj_stats_payload.append((f"CellString_{zoom}", lengths))
        traj_stats_summary = _print_trajectory_stats(traj_stats_payload, len(trajectory_ids))

        if stop_poly_area_size:
            stop_stats_payload.append(("LineString", stop_poly_area_size))
        for zoom in ZOOM_LEVELS:
            lengths = stop_cellstring_lengths.get(zoom)
            if lengths:
                stop_stats_payload.append((f"CellString_{zoom}", lengths))
        stop_stats_summary = _print_stop_stats(stop_stats_payload, len(stop_ids))

        all_tables_used = sorted({table for entry in benchmark_outputs for table in entry["tables_used"]})

        tested_types = []
        if traj_stats_summary:
            tested_types.extend(entry["label"] for entry in traj_stats_summary)
        if stop_stats_summary:
            tested_types.extend(entry["label"] for entry in stop_stats_summary)

        report = {
            "meta": {
                "run_started_at": run_started_at.isoformat(),
                "trajectory_count": len(trajectory_ids),
                "trajectory_ids": trajectory_ids,
                "stop_count": len(stop_ids),
                "stop_ids": stop_ids,
                "zoom_levels": ZOOM_LEVELS,
                "trajectory_stats": traj_stats_summary,
                "stop_stats": stop_stats_summary,
                "tested_types": tested_types,
                "tables_used": all_tables_used,
                "trajectory_linestring_lengths_m": {
                    str(traj_id): length for traj_id, length in linestring_lengths_by_id.items()
                },
                "trajectory_cardinalities": {
                    zoom: {str(traj_id): count for traj_id, count in counts.items()}
                    for zoom, counts in cellstring_lengths.items()
                    if counts
                },
                "stop_polygon_areas_m2": {
                    str(stop_id): area for stop_id, area in zip(stop_ids, stop_poly_area_size)
                },
                "stop_cardinalities": {
                    zoom: counts for zoom, counts in stop_cellstring_lengths.items() if counts
                },
            },
            "benchmarks": benchmark_outputs,
        }
        _write_json_report(report, run_started_at)

    finally:
        conn.close()

if __name__ == "__main__":
    main()
