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


def _build_time_rows(
        benchmarks: List[Dict[str, Any]],
        length_stats: Dict[str, Dict[str, Any]],
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        st = bench["result"]["st"]
        st_exec_ms = st["exec_ms_med"]
        for zoom, cst in bench["result"]["cst_results"].items():
            label = f"CellString_{zoom}" if zoom else "CellString"
            stat = length_stats.get(label)
            rows.append(
                {
                    "benchmark": bench["name"],
                    "zoom": zoom or "n/a",
                    "median_length": stat["median"] if stat else None,
                    "delta_exec_ms": cst["exec_ms_med"] - st_exec_ms,
                    "st_exec_ms": st_exec_ms,
                    "cst_exec_ms": cst["exec_ms_med"],
                }
            )
    return rows


def plot_cellstring_delta(time_rows: List[Dict[str, Any]]) -> None:
    if not time_rows:
        print("No time benchmarks available for delta scatter.")
        return
    df = pd.DataFrame(time_rows)
    fig = px.scatter(
        df,
        x="median_length",
        y="delta_exec_ms",
        color="zoom",
        hover_data=["benchmark"],
        title="CellString vs. LineString wall-time delta",
        labels={"median_length": "Median trajectory length", "delta_exec_ms": "Execution delta (ms)"}
    )
    fig.add_hline(y=0, line_dash="dash", annotation_text="CellString == LineString")
    fig.write_image("benchmarking/graphs/output/cellstring_delta.pdf")


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