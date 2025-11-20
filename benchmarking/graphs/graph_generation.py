import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

import pandas as pd
import plotly.express as px


def _ensure_report_path(path_arg: Optional[str]) -> Path:
    if path_arg:
        candidate = Path(path_arg).expanduser()
        if not candidate.exists():
            raise FileNotFoundError(f"No report found at {candidate}")
        return candidate

    report_dir = Path("benchmarking/benchmark_results")
    if not report_dir.exists():
        raise FileNotFoundError(f"No report found at {report_dir}")
    reports = sorted(report_dir.glob("run_*.json"))
    if not reports:
        raise FileNotFoundError(f"No JSON reports inside {report_dir}")
    return reports[-1]


def _load_report(report_path: Path) -> Dict[str, Any]:
    print(f"Loading benchmarking report from {report_path}")
    return json.loads(report_path.read_text())


def _filter_benchmarks(benchmarks: List[Dict[str, Any]], selected: Optional[List[str]]) -> List[Dict[str, Any]]:
    if not selected:
        return benchmarks
    wanted = set(selected)
    return [bench for bench in benchmarks if bench["name"] in wanted]


def _get_cardinality_map(meta: Dict[str, Any], zoom: str) -> Dict[int, int]:
    card_data = meta.get("trajectory_cardinalities", {})
    zoom_card = card_data.get(zoom, {})
    return {int(traj_id): count for traj_id, count in zoom_card.items()}


def _build_sample_rows(
        samples: List[Dict[str, Any]],
        card_map: Dict[int, int],
        benchmark_name: str,
        series_label: str,
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for sample in samples:
        trajectory_id = sample.get("trajectory_id")
        exec_ms = sample.get("exec_ms")
        if trajectory_id is None or exec_ms is None:
            continue
        cell_count = card_map.get(int(trajectory_id))
        if cell_count is None:
            continue
        rows.append(
            {
                "benchmark": benchmark_name,
                "series": series_label,
                "trajectory_id": trajectory_id,
                "cell_count": cell_count,
                "exec_ms": exec_ms,
            }
        )
    return rows


def plot_cellstring_delta(
        benchmarks: List[Dict[str, Any]],
        meta: Dict[str, Any],
        *,
        zoom: str = "z21",
) -> None:
    card_map = _get_cardinality_map(meta, zoom)
    if not card_map:
        print(f"No trajectory cardinalities recorded for {zoom}; skipping CellString delta plot.")
        return

    rows: List[Dict[str, Any]] = []
    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        result = bench["result"]
        rows.extend(
            _build_sample_rows(result.get("st", {}).get("samples", []), card_map, bench["name"], "ST_")
        )
        cst_zoom = result.get("cst_results", {}).get(zoom)
        if cst_zoom:
            rows.extend(
                _build_sample_rows(cst_zoom.get("samples", []), card_map, bench["name"], f"CST_{zoom}")
            )

    if not rows:
        print("No per-trajectory execution samples available; skipping CellString delta plot.")
        return

    df = pd.DataFrame(rows)
    fig = px.scatter(
        df,
        x="cell_count",
        y="exec_ms",
        color="series",
        hover_data=["trajectory_id", "benchmark"],
        title=f"Execution time vs. "
    )


def plot_wall_time_bars(time_rows: List[Dict[str, Any]]) -> None:
    if not time_rows:
        print("No time benchmarks available for wall-time bars.")
        return
    bars: List[Dict[str, Any]] = []
    emitted_st: Dict[str, Any] = {}
    for row in time_rows:
        bench = row["benchmark"]
        if not emitted_st.get(bench):
            bars.append({"benchmark": bench, "series": "ST_", "exec_ms": row["st_exec_ms"]})
            emitted_st[bench] = True
        bars.append({"benchmark": bench, "series": f"CST_{row['zoom']})", "exec_ms": row["cst_exec_ms"]})
    df = pd.DataFrame(bars)
    fig = px.bar(
        df,
        x="benchmark",
        y="exec_ms",
        color="series",
        barmode="group",
        title="Execution time per benchmark",
        labels={"exec_ms": "Execution median (ms)"},
        log_y=True,
    )
    fig.write_image("benchmarking/graphs/output/exec_time_bars.pdf")


def plot_false_match_counts(benchmarks: List[Dict[str, Any]]) -> None:
    rows: List[Dict[str, Any]] = []
    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        for zoom, count in bench["result"]["false_positives"].items():
            rows.append(
                {"benchmark": bench["name"], "zoom": zoom or "n/a", "metric": "false_positives", "count": count}
            )
        for zoom, count in bench["result"]["false_negatives"].items():
            rows.append(
                {"benchmark": bench["name"], "zoom": zoom or "n/a", "metric": "false_negatives", "count": count}
            )
    if not rows:
        print("No false positive/negative data to plot.")
        return
    df = pd.DataFrame(rows)
    fig = px.bar(
        df,
        x="zoom",
        y="count",
        color="metric",
        facet_col="benchmark",
        barmode="group",
        title="False positives/negatives per benchmark",
    )
    fig.write_image("benchmarking/graphs/output/false_match_counts.pdf")


def run_all_graphs(report_path: Path) -> None:
    data = _load_report(report_path)
    length_stats = {entry["label"]: entry for entry in data["meta"].get("trajectory_stats", [])}
    time_rows = _build_time_rows(data["benchmarks"], length_stats)
    plot_cellstring_delta(time_rows)
    plot_wall_time_bars(time_rows)
    plot_false_match_counts(data["benchmarks"])


def main(path_arg: Optional[str] = None) -> None:
    report_path = _ensure_report_path(path_arg)
    run_all_graphs(report_path)


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    main(arg)