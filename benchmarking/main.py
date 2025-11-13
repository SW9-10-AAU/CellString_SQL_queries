import os
import sys
from dotenv import load_dotenv
from statistics import median
from benchmarking.connect import connect_to_db
from benchmarking.core import run_benchmark, print_result
from benchmarking.benchmarks import REGISTRY

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
            cur.execute("SELECT trajectory_id FROM prototype2.trajectory_ls ORDER BY random() LIMIT 400")
            trajectory_ids = [row[0] for row in cur.fetchall()]

            if trajectory_ids:
                cur.execute("SELECT cardinality(cellstring_z21) FROM prototype2.trajectory_cs WHERE trajectory_id = ANY(%s)", (trajectory_ids,))
                cellstring_lengths = [row[0] for row in cur.fetchall() if row[0] is not None]

        for benchmark in REGISTRY:
            print(f"Running benchmark:", benchmark.name)
            result = run_benchmark(conn, benchmark, trajectory_ids)
            print_result(result)

        if cellstring_lengths:
            print("\n--- Random LineString trajectory statistics ---")
            print(f"Min length: {min(cellstring_lengths)}")
            print(f"Median length: {median(cellstring_lengths)}")
            print(f"Max length: {max(cellstring_lengths)}")
            print(f"Count of trajectory ids: {len(cellstring_lengths)}")

    finally:
        conn.close()

if __name__ == "__main__":
    main()
