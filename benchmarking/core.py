from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from statistics import median
from typing import Any, Dict, Iterable, List, Sequence, Tuple


@dataclass(frozen=True)
class Benchmark:
    name: str
    st_sql: str
    cst_sql: str
    params: Tuple[Any, ...] = tuple()
    repeats: int = 5
    with_trajectory_ids: bool = False
    zoom_levels: List[str] = field(default_factory=list)


@dataclass
class RunOutcome:
    exec_ms_med: float
    wall_ms_med: float
    rows: List[Tuple]


@dataclass
class BenchmarkResult:
    name: str
    st: RunOutcome
    cst_results: Dict[str,RunOutcome]
    false_positives: Dict[str, int]
    false_negatives: Dict[str, int]


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


def _execute_queries_with_random_trajectories(cur, label: str, sql: str, params: Sequence[Any], trajectory_ids: List[int]) -> RunOutcome:
    if trajectory_ids:
        _warmup(cur, sql, (trajectory_ids[0],) + params)

    exec_times: List[float] = []
    wall_times: List[float] = []
    all_rows: List[Tuple] = []

    for trajectory_id in trajectory_ids:
        current_params = (trajectory_id,) + params
        _, exec_ms = _explain_analyze_ms(cur, sql, current_params)
        rows, wall_ms = _fetch_all_with_wall_ms(cur, sql, current_params)
        exec_times.append(exec_ms)
        wall_times.append(wall_ms)
        all_rows.extend(rows)

    return RunOutcome(
        exec_ms_med=round(median(exec_times), 3) if exec_times else 0.0,
        wall_ms_med=round(median(wall_times), 3) if wall_times else 0.0,
        rows=all_rows,
    )


def _execute_queries_repeated(cur, label: str, sql: str, params: Sequence[Any], repeats: int) -> RunOutcome:
    _warmup(cur, sql, params)

    exec_times: List[float] = []
    wall_times: List[float] = []

    for i in range(repeats):
        _, exec_ms = _explain_analyze_ms(cur, sql, params)
        exec_times.append(exec_ms)
        # Only run the last one for wall time and row count
        if i == repeats - 1:
            rows, wall_ms = _fetch_all_with_wall_ms(cur, sql, params)
            wall_times.append(wall_ms)

    return RunOutcome(
        exec_ms_med=round(median(exec_times), 3) if exec_times else 0.0,
        wall_ms_med=round(median(wall_times), 3) if wall_times else 0.0,
        rows=rows,
    )


def run_benchmark(connection, bench: Benchmark, trajectory_ids: List[int]) -> BenchmarkResult:
    connection.autocommit = True
    connection.prepare_threshold = None
    with connection.cursor() as cur:
        if bench.with_trajectory_ids:
            st_out = _execute_queries_with_random_trajectories(cur, "ST_", bench.st_sql, bench.params, trajectory_ids)
            cst_results = {}
            for zoom in bench.zoom_levels:
                sql = bench.cst_sql.format(zoom=zoom)
                cst_results[zoom] = _execute_queries_with_random_trajectories(cur, f"CST_{zoom}", sql, bench.params, trajectory_ids)
        else:
            st_out = _execute_queries_repeated(cur, "ST_", bench.st_sql, bench.params, bench.repeats)
            cst_results = {}
            for zoom in bench.zoom_levels:
                sql = bench.cst_sql.format(zoom=zoom)
                cst_results[zoom] = _execute_queries_repeated(cur, f"CST_{zoom}", sql, bench.params, bench.repeats)

    st_keys = _keyset(st_out.rows)
    false_positives = {}
    false_negatives = {}
    for zoom, cst_out in cst_results.items():
        cst_keys = _keyset(cst_out.rows)
        false_positives[zoom] = len(cst_keys - st_keys)
        false_negatives[zoom] = len(st_keys - cst_keys)

    return BenchmarkResult(
        name=bench.name,
        st=st_out,
        cst_results=cst_results,
        false_positives=false_positives,
        false_negatives=false_negatives,
    )


def print_result(result: BenchmarkResult) -> None:
    print(f"\n--- {result.name} ---")
    print(f"ST_:  exec_ms(median)={result.st.exec_ms_med},  wall_ms(median)={result.st.wall_ms_med}")
    print("----------------------------")
    for zoom, cst_out in result.cst_results.items():
        print(f"CST_{zoom}: exec_ms(median)={cst_out.exec_ms_med}, wall_ms(median)={cst_out.wall_ms_med}")
        print(f"False positives (CST_{zoom} \\ ST_): {result.false_positives[zoom]}")
        print(f"False negatives (ST_ \\ CST_{zoom}): {result.false_negatives[zoom]}")
        print("----------------------------\n")
