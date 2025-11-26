from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from statistics import median
from typing import Any, Dict, Iterable, List, Sequence, Tuple


@dataclass(frozen=True)
class TimeBenchmark:
    name: str
    st_sql: str
    cst_sql: str
    params: Tuple[Any, ...] = tuple()
    repeats: int = 5
    with_trajectory_ids: bool = False
    with_stop_ids: bool = False
    zoom_levels: List[str] = field(default_factory=list)
    area_ids: List[int] = field(default_factory=list)
    use_area_ids: bool = False
    timeout_seconds: int = 120


@dataclass(frozen=True)
class ValueBenchmark:
    name: str
    sql: str
    zoom_levels: List[str] = field(default_factory=list)


@dataclass
class RunOutcome:
    exec_ms_med: float
    wall_ms_med: float
    rows: List[Tuple]
    timed_out: bool = False


@dataclass
class TimeBenchmarkResult:
    name: str
    st: RunOutcome
    cst_results: Dict[str,RunOutcome]
    false_positives: Dict[str, int]
    false_negatives: Dict[str, int]
    per_area_results: Dict[int, Dict[str, RunOutcome]] = field(default_factory=dict)


@dataclass
class ValueBenchmarkResult:
    name: str
    median_values: Dict[str, float]


def _discard_and_set(cur, statement_timeout_seconds: int | None = None) -> None:
    # Must be outside a transaction. autocommit is set on the connection.
    cur.execute("DISCARD ALL")
    cur.execute("SET jit = off")
    if statement_timeout_seconds is not None:
        cur.execute(f"SET statement_timeout = '{statement_timeout_seconds}s'")


def _explain_analyze_ms(
        cur, sql: str, params: Sequence[Any], statement_timeout_seconds: int | None = None
) -> Tuple[float, float]:
    _discard_and_set(cur, statement_timeout_seconds)
    cur.execute("EXPLAIN (ANALYZE, BUFFERS, TIMING ON, FORMAT JSON) " + sql, params)
    payload = cur.fetchone()[0]
    data = payload[0] if isinstance(payload, list) else json.loads(payload)[0]
    return float(data.get("Planning Time", 0.0)), float(data.get("Execution Time", 0.0))


def _fetch_all_with_wall_ms(
        cur, sql: str, params: Sequence[Any], statement_timeout_seconds: int | None = None
) -> Tuple[List[Tuple], float]:
    _discard_and_set(cur, statement_timeout_seconds)
    start = time.perf_counter()
    cur.execute(sql, params)
    rows = cur.fetchall()
    return rows, (time.perf_counter() - start) * 1000.0


def _warmup(cur, sql: str, params: Sequence[Any], statement_timeout_seconds: int | None = None) -> None:
    _discard_and_set(cur, statement_timeout_seconds)
    cur.execute(sql, params)
    cur.fetchall()


def _median_or_zero(values: Iterable[float]) -> float:
    values = list(values)
    return round(median(values), 3) if values else 0.0


def _aggregate_runs(runs: List[RunOutcome], rows: List[Tuple]) -> RunOutcome:
    return RunOutcome(
        exec_ms_med=_median_or_zero(r.exec_ms_med for r in runs),
        wall_ms_med=_median_or_zero(r.wall_ms_med for r in runs),
        rows=rows,
    )


def _keyset(rows: Iterable[Tuple]) -> set:
    return {r[0] for r in rows}


def _execute_random_or_repeated_queries(
        cur,
        sql: str,
        params: Sequence[Any],
        *,
        repeats: int | None = None,
        timeout_seconds: int | None,
        trajectory_ids: List[int] | None = None,
        stop_ids: List[int] | None = None,
) -> RunOutcome:
    if trajectory_ids is not None and not trajectory_ids:
        return RunOutcome(0.0, 0.0, [])

    exec_times: List[float] = []
    wall_times: List[float] = []
    collected_rows: List[Tuple] = []

    try:
        if trajectory_ids is not None:
            first_params = (trajectory_ids[0],) + params
            _warmup(cur, sql, first_params, timeout_seconds)

            for trajectory_id in trajectory_ids:
                current_params = (trajectory_id,) + params
                rows, wall_ms = _fetch_all_with_wall_ms(cur, sql, current_params, timeout_seconds)
                _, exec_ms = _explain_analyze_ms(cur, sql, current_params)
                exec_times.append(exec_ms)
                wall_times.append(wall_ms)
                collected_rows.extend(rows)
        elif stop_ids is not None:
            first_params = (stop_ids[0],) + params
            _warmup(cur, sql, first_params, timeout_seconds)

            for stop_id in stop_ids:
                current_params = (stop_id,) + params
                rows, wall_ms = _fetch_all_with_wall_ms(cur, sql, current_params, timeout_seconds)
                _, exec_ms = _explain_analyze_ms(cur, sql, current_params)
                exec_times.append(exec_ms)
                wall_times.append(wall_ms)
                collected_rows.extend(rows)
        else:
            _warmup(cur, sql, params, timeout_seconds)
            rows, wall_ms = _fetch_all_with_wall_ms(cur, sql, params, timeout_seconds)
            wall_times.append(wall_ms)
            collected_rows = rows
            for _ in range(repeats):
                _, exec_ms = _explain_analyze_ms(cur, sql, params)
                exec_times.append(exec_ms)

        _discard_and_set(cur)
        return RunOutcome(_median_or_zero(exec_times), _median_or_zero(wall_times), collected_rows)
    except Exception as exc:
        if timeout_seconds is None:
            raise
        is_timeout = "canceling statement due to statement timeout" in str(exc)
        try:
            cur.connection.rollback()
            _discard_and_set(cur)
        except Exception as rollback_exc:
            print("Error during rollback after timeout:", rollback_exc)
        if is_timeout:
            return RunOutcome(0.0, 0.0, [], timed_out=True)
        raise


def run_time_benchmark(connection, bench: TimeBenchmark, trajectory_ids: List[int] | None = None, stop_ids: List[int] | None = None) -> TimeBenchmarkResult:
    connection.autocommit = True
    connection.prepare_threshold = None
    per_area_results: Dict[int, Dict[str, RunOutcome]] = {}

    with connection.cursor() as cur:
        if bench.use_area_ids and bench.area_ids:
            st_rows: List[Tuple] = []
            valid_st_runs: List[RunOutcome] = []
            cst_combined: Dict[str, List[Tuple]] = {zoom: [] for zoom in bench.zoom_levels}
            cst_valid_runs: Dict[str, List[RunOutcome]] = {zoom: [] for zoom in bench.zoom_levels}

            for area_id in bench.area_ids:
                area_params = (area_id,) + bench.params
                st_run = _execute_random_or_repeated_queries(
                    cur, bench.st_sql, area_params, repeats=bench.repeats, timeout_seconds=bench.timeout_seconds
                )
                per_area_results[area_id] = {"ST_": st_run}
                if not st_run.timed_out:
                    st_rows.extend(st_run.rows)
                    valid_st_runs.append(st_run)

                for zoom in bench.zoom_levels:
                    sql = bench.cst_sql.format(zoom=zoom)
                    cst_run = _execute_random_or_repeated_queries(
                        cur, sql, area_params, repeats=bench.repeats, timeout_seconds=bench.timeout_seconds
                    )
                    per_area_results[area_id][f"CST_{zoom}"] = cst_run
                    if not cst_run.timed_out:
                        cst_combined[zoom].extend(cst_run.rows)
                        cst_valid_runs[zoom].append(cst_run)

            st_out = _aggregate_runs(valid_st_runs, st_rows)
            cst_results = {
                zoom: _aggregate_runs(cst_valid_runs[zoom], cst_combined[zoom]) for zoom in bench.zoom_levels
            }
        elif bench.with_trajectory_ids:
            st_out = _execute_random_or_repeated_queries(
                cur,
                bench.st_sql,
                bench.params,
                timeout_seconds=bench.timeout_seconds,
                trajectory_ids=trajectory_ids
            )
            cst_results = {}
            for zoom in bench.zoom_levels:
                sql = bench.cst_sql.format(zoom=zoom)
                cst_results[zoom] = _execute_random_or_repeated_queries(
                    cur,
                    sql,
                    bench.params,
                    timeout_seconds=bench.timeout_seconds,
                    trajectory_ids=trajectory_ids
                )
        elif bench.with_stop_ids:
            st_out = _execute_random_or_repeated_queries(
                cur,
                bench.st_sql,
                bench.params,
                timeout_seconds=bench.timeout_seconds,
                stop_ids=stop_ids
            )
            cst_results = {}
            for zoom in bench.zoom_levels:
                sql = bench.cst_sql.format(zoom=zoom)
                cst_results[zoom] = _execute_random_or_repeated_queries(
                    cur,
                    sql,
                    bench.params,
                    timeout_seconds=bench.timeout_seconds,
                    stop_ids=stop_ids
                )
        else:
            st_out = _execute_random_or_repeated_queries(
                cur, bench.st_sql, bench.params, repeats=bench.repeats, timeout_seconds=bench.timeout_seconds
            )
            cst_results = {}
            if bench.zoom_levels:
                for zoom in bench.zoom_levels:
                    sql = bench.cst_sql.format(zoom=zoom)
                    cst_results[zoom] = _execute_random_or_repeated_queries(
                        cur, sql, bench.params, repeats=bench.repeats, timeout_seconds=bench.timeout_seconds
                    )
            else:
                cst_results[""] = _execute_random_or_repeated_queries(
                    cur, bench.cst_sql, bench.params, repeats=bench.repeats, timeout_seconds=bench.timeout_seconds
                )

    st_keys = _keyset(st_out.rows)
    false_positives: Dict[str, int] = {}
    false_negatives: Dict[str, int] = {}
    for zoom, cst_out in cst_results.items():
        cst_keys = _keyset(cst_out.rows)
        false_positives[zoom] = len(cst_keys - st_keys)
        false_negatives[zoom] = len(st_keys - cst_keys)

    return TimeBenchmarkResult(bench.name, st_out, cst_results, false_positives, false_negatives, per_area_results,)


def run_value_benchmark(connection, bench: ValueBenchmark, trajectory_ids: List[int]) -> ValueBenchmarkResult:
    connection.autocommit = True
    connection.prepare_threshold = None
    median_values: Dict[str, float] = {}

    with connection.cursor() as cur:
        for zoom in bench.zoom_levels:
            zoom_level_int = int(zoom.replace('z', ''))
            sql = bench.sql.format(zoom=zoom, zoom_level=zoom_level_int)
            values = []
            for trajectory_id in trajectory_ids:
                cur.execute(sql, (trajectory_id,))
                row = cur.fetchone()
                if row and row[0] is not None:
                    values.append(row[0])
            if values:
                median_values[zoom] = median(values)

    return ValueBenchmarkResult(bench.name, median_values)

def _print_run(label: str, run: RunOutcome, indent: str = "") -> None:
    if run.timed_out:
        print(f"{indent}{label}: (TIMEOUT)")
    else:
        print(f"{indent}{label}: exec_ms(median)={run.exec_ms_med}, wall_ms(median)={run.wall_ms_med}")

def print_time_result(result: TimeBenchmarkResult) -> None:
    print(f"\n--- {result.name} ---")
    _print_run("ST_", result.st)
    print("----------------------------")
    for zoom, cst_out in result.cst_results.items():
        zoom_label = f"CST_{zoom}" if zoom else "CST_"
        _print_run(zoom_label, cst_out)
        if not cst_out.timed_out:
            fp_key = zoom if zoom else ""
            fn_key = zoom if zoom else ""
            print(f"False positives ({zoom_label} \\ ST_): {result.false_positives[fp_key]}")
            print(f"False negatives (ST_ \\ {zoom_label}): {result.false_negatives[fn_key]}")
        print("----------------------------")
    if result.per_area_results:
        print("Per-area breakdown:")
        for area_id in sorted(result.per_area_results):
            print(f"Area {area_id}:")
            for label, run in result.per_area_results[area_id].items():
                _print_run(f"  {label}", run)
            print("----------------------------")


def print_value_result(result: ValueBenchmarkResult) -> None:
    print(f"\n--- {result.name} ---")
    for zoom, value in result.median_values.items():
        zoom_label = f"Zoom {zoom}" if zoom else "No zoom"
        print(f"{zoom_label}: median value = {value:.10f}")
    print("----------------------------")