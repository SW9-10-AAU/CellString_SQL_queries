from __future__ import annotations

import json
import time
from dataclasses import dataclass
from statistics import median
from typing import Any, Iterable, List, Sequence, Tuple


@dataclass(frozen=True)
class Benchmark:
    name: str
    st_sql: str
    cst_sql: str
    params: Tuple[Any, ...] = tuple()
    repeats: int = 5


@dataclass
class RunOutcome:
    exec_ms_med: float
    wall_ms_med: float
    rows: List[Tuple]


@dataclass
class BenchmarkResult:
    name: str
    st: RunOutcome
    cst: RunOutcome
    false_positives: int
    false_negatives: int


def _discard_and_set(cur) -> None:
    # Must be outside a transaction. autocommit is set on the connection.
    cur.execute("DISCARD ALL")
    cur.execute("SET jit = off")


def _explain_analyze_ms(cur, sql: str, params: Sequence[Any]) -> Tuple[float, float]:
    _discard_and_set(cur)
    cur.execute("EXPLAIN (ANALYZE, BUFFERS, TIMING ON, FORMAT JSON) " + sql, params)
    payload = cur.fetchone()[0]
    data = payload[0] if isinstance(payload, list) else json.loads(payload)[0]
    planning_ms = float(data.get("Planning Time", 0.0))
    execution_ms = float(data.get("Execution Time", 0.0))
    return planning_ms, execution_ms


def _fetch_all_with_wall_ms(cur, sql: str, params: Sequence[Any]) -> Tuple[List[Tuple], float]:
    _discard_and_set(cur)
    start = time.perf_counter()
    cur.execute(sql, params)
    rows = cur.fetchall()
    wall_ms = (time.perf_counter() - start) * 1000.0
    return rows, wall_ms


def _warmup(cur, sql: str, params: Sequence[Any]) -> None:
    _discard_and_set(cur)
    cur.execute(sql, params)
    _ = cur.fetchall()


def _keyset(rows: Iterable[Tuple]) -> set:
    return set(r[0] for r in rows)


def _run_one_side(cur, label: str, sql: str, params: Sequence[Any], repeats: int) -> RunOutcome:
    _warmup(cur, sql, params)

    exec_times: List[float] = []
    wall_times: List[float] = []
    last_rows: List[Tuple] = []

    for _ in range(repeats):
        _, exec_ms = _explain_analyze_ms(cur, sql, params)
        rows, wall_ms = _fetch_all_with_wall_ms(cur, sql, params)
        exec_times.append(exec_ms)
        wall_times.append(wall_ms)
        last_rows = rows

    return RunOutcome(
        exec_ms_med=round(median(exec_times), 3),
        wall_ms_med=round(median(wall_times), 3),
        rows=last_rows,
    )


def run_benchmark(connection, bench: Benchmark) -> BenchmarkResult:
    # Ensure consistent session settings on this connection.
    connection.autocommit = True
    connection.prepare_threshold = None  # disable automatic prepares
    with connection.cursor() as cur:
        st_out = _run_one_side(cur, "ST_", bench.st_sql, bench.params, bench.repeats)
        cst_out = _run_one_side(cur, "CST_", bench.cst_sql, bench.params, bench.repeats)

    st_keys = _keyset(st_out.rows)
    cst_keys = _keyset(cst_out.rows)
    false_positives = len(cst_keys - st_keys)
    false_negatives = len(st_keys - cst_keys)

    return BenchmarkResult(
        name=bench.name,
        st=st_out,
        cst=cst_out,
        false_positives=false_positives,
        false_negatives=false_negatives,
    )


def print_result(result: BenchmarkResult) -> None:
    print(f"\n--- {result.name} ---")
    print(f"ST_:  exec_ms(median)={result.st.exec_ms_med},  wall_ms(median)={result.st.wall_ms_med}")
    print(f"CST_: exec_ms(median)={result.cst.exec_ms_med}, wall_ms(median)={result.cst.wall_ms_med}")
    print(f"False positives (CST_ \\ ST_): {result.false_positives}")
    print(f"False negatives (ST_ \\ CST_): {result.false_negatives}")
