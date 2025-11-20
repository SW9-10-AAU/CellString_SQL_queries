import os
import sys
from dataclasses import replace
from statistics import median
from dotenv import load_dotenv
from benchmarking.connect import connect_to_db
from benchmarking.core import (
    run_time_benchmark,
    print_time_result,
    TimeBenchmark,
    ValueBenchmark,
    run_value_benchmark,
    print_value_result
)
from benchmarking.benchmarks import RUN_PLAN


ZOOM_LEVELS = ["z13", "z17", "z21"]


def _get_area_ids(conn, selected_ids=None):
    with conn.cursor() as cur:
        cur.execute("SELECT DISTINCT area_id FROM benchmark.area_poly ORDER BY area_id")
        all_area_ids = [row[0] for row in cur.fetchall()]

        if selected_ids:
            return [aid for aid in selected_ids if aid in all_area_ids]
        return all_area_ids


def _print_trajectory_stats(stat_entries, sample_size):
    if not stat_entries:
        return
    print(f"\n{sample_size} trajectory statistics:")
    for label, lengths in stat_entries:
        if not lengths:
            continue
        print(
            f"{label}: Min length: {min(lengths)}, "
            f"Median length: {median(lengths)}, "
            f"Max length: {max(lengths)}"
        )


def main():
    load_dotenv()
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        sys.exit("DATABASE_URL not defined in .env file")


    conn = connect_to_db()
    try:
        trajectory_ids = []
        linestring_lengths = []
        cellstring_lengths = {zoom: [] for zoom in ZOOM_LEVELS}

        with conn.cursor() as cur:
            cur.execute("SELECT trajectory_id FROM prototype2.trajectory_ls ORDER BY random() LIMIT 5")
            trajectory_ids = [row[0] for row in cur.fetchall()]

            if trajectory_ids:
                cur.execute(
                    "SELECT ST_Length(ST_Transform(geom, 3857)) FROM prototype2.trajectory_ls WHERE trajectory_id = ANY(%s)",
                    (trajectory_ids,)
                )
                linestring_lengths = [row[0] for row in cur.fetchall() if row[0] is not None]

                for zoom in ZOOM_LEVELS:
                    cur.execute(
                        f"SELECT Cardinality(cellstring_{zoom}) "
                        "FROM prototype2.trajectory_cs WHERE trajectory_id = ANY(%s)",
                        (trajectory_ids,)
                    )
                    cellstring_lengths[zoom] = [row[0] for row in cur.fetchall() if row[0] is not None]

        for benchmark in RUN_PLAN:
            if isinstance(benchmark, TimeBenchmark) and benchmark.use_area_ids and not benchmark.area_ids:
                all_area_ids = _get_area_ids(conn)
                benchmark = replace(benchmark, area_ids=all_area_ids)

            print(f"\nRunning benchmark:", benchmark.name)
            if isinstance(benchmark, TimeBenchmark):
                result = run_time_benchmark(conn, benchmark, trajectory_ids)
                print_time_result(result)
            elif isinstance(benchmark, ValueBenchmark):
                result = run_value_benchmark(conn, benchmark, trajectory_ids)
                print_value_result(result)

        stats_payload = []
        if linestring_lengths:
            stats_payload.append(("LineString", linestring_lengths))
        for zoom in ZOOM_LEVELS:
            lengths = cellstring_lengths.get(zoom)
            if lengths:
                stats_payload.append((f"CellString_{zoom}", lengths))
        _print_trajectory_stats(stats_payload, len(trajectory_ids))

    finally:
        conn.close()

if __name__ == "__main__":
    main()
