import os
import sys
from dotenv import load_dotenv
from statistics import median
from dataclasses import replace
from benchmarking.connect import connect_to_db
from benchmarking.core import run_time_benchmark, print_time_result, TimeBenchmark, ValueBenchmark, run_value_benchmark, print_value_result
from benchmarking.benchmarks import RUN_PLAN

def _get_area_ids(conn, selected_ids=None):
    with conn.cursor() as cur:
        cur.execute("SELECT DISTINCT area_id FROM benchmark.area_poly ORDER BY area_id")
        all_area_ids = [row[0] for row in cur.fetchall()]

        if selected_ids:
            return [aid for aid in selected_ids if aid in all_area_ids]
        return all_area_ids

def main():
    load_dotenv()
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        sys.exit("DATABASE_URL not defined in .env file")

    conn = connect_to_db()
    try:
        trajectory_ids = []
        cellstring_lengths = []
        with conn.cursor() as cur:
            cur.execute("SELECT trajectory_id FROM prototype2.trajectory_ls ORDER BY random() LIMIT 5")
            trajectory_ids = [row[0] for row in cur.fetchall()]

            if trajectory_ids:
                cur.execute("SELECT cardinality(cellstring_z21) FROM prototype2.trajectory_cs WHERE trajectory_id = ANY(%s)", (trajectory_ids,))
                cellstring_lengths = [row[0] for row in cur.fetchall() if row[0] is not None]

        for benchmark in RUN_PLAN:
            if isinstance(benchmark, TimeBenchmark) and benchmark.use_area_ids:
                if not benchmark.area_ids:
                    all_area_ids = _get_area_ids(conn)
                    benchmark = replace(benchmark, area_ids=all_area_ids)
            print(f"\nRunning benchmark:", benchmark.name)
            if isinstance(benchmark, TimeBenchmark):
                result = run_time_benchmark(conn, benchmark, trajectory_ids)
                print_time_result(result)
            elif isinstance(benchmark, ValueBenchmark):
                result = run_value_benchmark(conn, benchmark, trajectory_ids)
                print_value_result(result)

        if cellstring_lengths:
            print("\n--- Random CellString_z21 trajectory statistics ---")
            print(f"Min length: {min(cellstring_lengths)}")
            print(f"Median length: {median(cellstring_lengths)}")
            print(f"Max length: {max(cellstring_lengths)}")
            print(f"Count of trajectory ids: {len(cellstring_lengths)}")

    finally:
        conn.close()

if __name__ == "__main__":
    main()
