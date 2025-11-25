import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

import pandas as pd
import plotly.express as px


OUTPUT_DIR = Path("benchmarking/graphs/output")


def _next_output_path(base_name: str, extension: str = ".pdf") -> Path:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    counter_file = OUTPUT_DIR / f".{base_name}_counter"
    last_index = 0
    if counter_file.exists():
        try:
            last_index = int(counter_file.read_text().strip())
        except ValueError:
            last_index = 0
    next_index = last_index + 1
    counter_file.write_text(str(next_index))
    return OUTPUT_DIR / f"{base_name}_{next_index}{extension}"


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
        st_samples = {
            int(sample["trajectory_id"]): sample
            for sample in result.get("st", {}).get("samples", [])
            if sample.get("trajectory_id") is not None and sample.get("exec_ms") is not None
        }
        cst_zoom = result.get("cst_results", {}).get(zoom)
        if not cst_zoom:
            continue
        cst_samples = {
            int(sample["trajectory_id"]): sample
            for sample in cst_zoom.get("samples", [])
            if sample.get("trajectory_id") is not None and sample.get("exec_ms") is not None
        }
        for traj_id, st_sample in st_samples.items():
            cst_sample = cst_samples.get(traj_id)
            cell_count = card_map.get(traj_id)
            if not cst_sample or cell_count is None:
                continue
            rows.append(
                {
                    "benchmark": bench["name"],
                    "trajectory_id": traj_id,
                    "cell_count": cell_count,
                    "delta_exec_ms": cst_sample["exec_ms"] - st_sample["exec_ms"],
                    "st_exec_ms": st_sample["exec_ms"],
                    "cst_exec_ms": cst_sample["exec_ms"],
                }
            )

    if not rows:
        print("No paired ST_/CST_ samples with cardinalities; skipping CellString delta plot.")
        return

    df = pd.DataFrame(rows).sort_values(["benchmark", "cell_count"])
    fig = px.line(
        df,
        x="cell_count",
        y="delta_exec_ms",
        color="benchmark",
        hover_data=["trajectory_id", "st_exec_ms", "cst_exec_ms"],
        title=f"CST - ST execution delta vs. CellString cardinality ({zoom})",
        labels={"cell_count": f"Cell count @{zoom}", "exec_ms": "Execution time (ms)"},
        markers=False,
        log_x=True,
    )
    fig.add_hline(y=0, line_dash="dash", annotation_text="CellString == LineString")
    fig.update_layout(
        width=1100,
        height=650,
        margin=dict(l=60, r=30, t=70, b=90),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="left",
            x=0.0,
            title="Benchmark",
        )
    )
    output_path = _next_output_path("cellstring_delta")
    fig.write_image(output_path)
    print(f"Wrote CellString delta plot to {output_path}")


def plot_exec_time_bars(time_rows: List[Dict[str, Any]]) -> None:
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
        bars.append({"benchmark": bench, "series": f"CST_{row['zoom']}", "exec_ms": row["cst_exec_ms"]})
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
    output_path = _next_output_path("exec_time_bars")
    fig.write_image(output_path)
    print(f"Wrote Execution time bars to {output_path}")


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
        log_y=True,
    )
    output_path = _next_output_path("false_match_counts")
    fig.write_image(output_path)
    print(f"Wrote False Match Counts plot to {output_path}")


def run_all_graphs(report_path: Path, selected_benchmarks: Optional[List[str]] = None) -> None:
    data = _load_report(report_path)
    benchmarks = _filter_benchmarks(data["benchmarks"], selected_benchmarks)
    if not benchmarks:
        print("No benchmarks matched the requested filters; nothing to plot.")
        return

    length_stats = {entry["label"]: entry for entry in data["meta"].get("trajectory_stats", [])}
    time_rows = _build_time_rows(data["benchmarks"], length_stats)
    plot_cellstring_delta(benchmarks, data["meta"], zoom="z21")
    plot_exec_time_bars(time_rows)
    plot_false_match_counts(benchmarks)


def main(path_arg: Optional[str] = None, benchmarks: Optional[List[str]] = None) -> None:
    report_path = _ensure_report_path(path_arg)
    run_all_graphs(report_path, benchmarks)


if __name__ == "__main__":
    args = sys.argv[1:]
    report_arg: Optional[str] = None
    benchmark_filters: List[str] = []
    for arg in args:
        if arg.startswith("--benchmark="):
            benchmark_filters.append(arg.split("=", 1)[1])
        elif arg.startswith("--benchmarks="):
            benchmark_filters.extend(
                filter(None, (name.strip() for name in arg.split("=", 1)[1].split(",")))
            )
        elif report_arg is None:
            report_arg = arg
        else:
            benchmark_filters.append(arg)
    main(report_arg, benchmark_filters or None)