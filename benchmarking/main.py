import os
import sys
from dotenv import load_dotenv
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
        for benchmark in REGISTRY:
            result = run_benchmark(conn, benchmark)
            print_result(result)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
