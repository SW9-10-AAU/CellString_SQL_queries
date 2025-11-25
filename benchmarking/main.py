import json
import os
import re
import sys
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from statistics import median
from typing import Dict
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
    stats = _build_length_stats(stat_entries)
    if not stats:
        return []
    print(f"\n{sample_size} trajectory statistics:")
    for entry in stats:
        print(
            f"{entry['label']}: Min length: {entry['min']}, "
            f"Median length: {entry['median']}, "
            f"Max length: {entry['max']}"
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
        linestring_lengths_by_id: Dict[int, float] = {}
        cellstring_lengths: Dict[str, Dict[int, int]] = {zoom: {} for zoom in ZOOM_LEVELS}
        benchmark_outputs = []

        with conn.cursor() as cur:
            cur.execute("SELECT trajectory_id FROM prototype2.trajectory_ls ORDER BY random() LIMIT 50")
            trajectory_ids = [row[0] for row in cur.fetchall()]

            if trajectory_ids:
                cur.execute(
                    "SELECT trajectory_id, ST_Length(ST_Transform(geom, 3857)) FROM prototype2.trajectory_ls WHERE trajectory_id = ANY(%s)",
                    (trajectory_ids,)
                )
                linestring_lengths_by_id = {
                    int(row[0]): row[1]
                    for row in cur.fetchall()
                    if row[0] is not None and row[1] is not None
                }

                for zoom in ZOOM_LEVELS:
                    cur.execute(
                        f"SELECT trajectory_id, Cardinality(cellstring_{zoom}) "
                        "FROM prototype2.trajectory_cs WHERE trajectory_id = ANY(%s)",
                        (trajectory_ids,)
                    )
                    cellstring_lengths[zoom] = {
                        int(row[0]): row[1]
                        for row in cur.fetchall()
                        if row[0] is not None and row[1] is not None
                    }

        for benchmark in RUN_PLAN:
            bench_instance = benchmark
            if isinstance(bench_instance, TimeBenchmark) and bench_instance.use_area_ids and not bench_instance.area_ids:
                all_area_ids = _get_area_ids(conn)
                bench_instance = replace(bench_instance, area_ids=all_area_ids)

            print(f"\nRunning benchmark:", bench_instance.name)
            tables_used = _collect_tables_from_benchmark(bench_instance)

            if isinstance(bench_instance, TimeBenchmark):
                result = run_time_benchmark(conn, bench_instance, trajectory_ids)
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
                result = run_value_benchmark(conn, bench_instance, trajectory_ids)
                print_value_result(result)
                benchmark_outputs.append(
                    {
                        "name": bench_instance.name,
                        "benchmark_type": "value",
                        "tables_used": tables_used,
                        "result": _serialize_value_result(result),
                    }
                )

        stats_payload = []
        if linestring_lengths_by_id:
            stats_payload.append(("LineString", list(linestring_lengths_by_id.values())))
        for zoom in ZOOM_LEVELS:
            lengths = list(cellstring_lengths.get(zoom, {}).values())
            if lengths:
                stats_payload.append((f"CellString_{zoom}", lengths))
        stats_summary = _print_trajectory_stats(stats_payload, len(trajectory_ids))
        all_tables_used = sorted({table for entry in benchmark_outputs for table in entry["tables_used"]})

        report = {
            "meta": {
                "run_started_at": run_started_at.isoformat(),
                "trajectory_count": len(trajectory_ids),
                "trajectory_ids": trajectory_ids,
                "zoom_levels": ZOOM_LEVELS,
                "trajectory_stats": stats_summary,
                "tested_types": [entry["label"] for entry in stats_summary],
                "tables_used": all_tables_used,
                "trajectory_cardinalities": {
                    zoom: {str(traj_id): count for traj_id, count in counts.items()}
                    for zoom, counts in cellstring_lengths.items()
                    if counts
                }
            },
            "benchmarks": benchmark_outputs,
        }
        _write_json_report(report, run_started_at)

    finally:
        conn.close()

if __name__ == "__main__":
    main()
