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


def _get_linestring_length_map(meta: Dict[str, Any]) -> Dict[int, float]:
    length_map: Dict[int, float] = {}
    candidates = [
        {"trajectory_lengths_km", 1.0},
        {"trajectory_linestring_lengths_km", 1.0},
        {"trajectory_lengths_m", 0.001},
        {"trajectory_linestring_lengths_m", 0.001},
    ]

    for key, scale in candidates:
        lengths = meta.get(key)
        if not isinstance(lengths, dict):
            continue

        for traj_id, value in lengths.items():
            if value is None:
                continue
            try:
                length_map[int(traj_id)] = float(value) * scale
            except (TypeError, ValueError):
                continue

        if length_map:
            break

    return length_map

def _get_stop_area_map(meta: Dict[str, Any]) -> Dict[int, float]:
    candidates = (
        "stop_polygon_areas_m2",
        "stop_polygons_area_m2",
        "stop_areas_m2",
        "stop_area_m2",
    )
    for key in candidates:
        raw = meta.get(key)
        if not raw:
            continue
        normalized: Dict[int, float] = {}
        for stop_id, area_m2 in raw.items():
            try:
                normalized[int(stop_id)] = float(area_m2)
            except (TypeError, ValueError):
                continue
        if normalized:
            return normalized
    return {}


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


def _apply_transparent_theme(fig, legend_horizontal: Optional[bool] = None, with_bar_text: Optional[bool] = None, left_legend: Optional[bool] = None) -> None:
    fig.update_layout(
        paper_bgcolor="rgba(0,0,0,0)",
        plot_bgcolor="rgba(0,0,0,0)",
        legend_bgcolor="rgba(0,0,0,0)",
        margin=dict(l=60, r=15, t=15, b=60),
        legend_title=dict(text=""),
        font_size=18,
        legend_font_size=25,
        legend_font_weight=550,
        legend_itemsizing="constant",
    )
    fig.update_xaxes(
        showgrid=False,
        showline=True,
        linewidth=2,
        linecolor="black",
        ticks="inside",
        mirror=True,
        minorloglabels="complete",
        tickfont_size=20,
    )
    fig.update_yaxes(
        showgrid=False,
        showline=True,
        linewidth=2,
        linecolor="black",
        ticks="inside",
        mirror=True,
        minorloglabels="complete",
        tickfont_size=20,
        automargin="left",
    )
    if with_bar_text:
        fig.update_traces(
            marker=dict(line_color="grey", pattern_fillmode="replace"),
            textfont_size=20,
            textangle=0,
            textposition="outside",
            cliponaxis=False,
        )
    if legend_horizontal is None and left_legend is None:
        fig.update_layout(
            legend=dict(
                yanchor="top",
                y=0.98,
                xanchor="right",
                x=0.98,
            )
        )
    elif legend_horizontal is None and left_legend:
        fig.update_layout(
            legend=dict(
                yanchor="top",
                y=0.98,
                xanchor="left",
                x=0.02,
            ),
        )
    else:
        fig.update_layout(
            legend=dict(
                orientation="h",
                entrywidth=120,
                yanchor="top",
                y=0.98,
                xanchor="left",
                x=0.02,
            ),
        )


def plot_cellstring_delta(benchmarks: List[Dict[str, Any]], meta: Dict[str, Any]) -> None:
    length_map = _get_linestring_length_map(meta)
    if not length_map:
        print("No LineString length data found in the report; skipping Execution time vs. LineString length plot.")
        return

    rows: List[Dict[str, Any]] = []

    def _collect_samples(samples: List[Dict[str, Any]], series: str, bench_name: str) -> None:
        for sample in samples or []:
            traj_id = sample.get("trajectory_id")
            exec_ms = sample.get("exec_ms")
            if traj_id is None or exec_ms is None:
                continue
            length_km = length_map.get(int(traj_id))
            if length_km is None:
                continue
            rows.append(
                {
                    "benchmark": bench_name,
                    "series": series,
                    "trajectory_id": traj_id,
                    "length_km": length_km,
                    "exec_ms": exec_ms,
                }
            )

    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        result = bench["result"]
        _collect_samples(result.get("st", {}). get("samples", []), "LineString", bench["name"])
        for zoom, cst in result.get("cst_results", {}).items():
            label = zoom or "CellString"
            _collect_samples(cst.get("samples", []), label, bench["name"])

    if not rows:
        print("No benchmark samples with LineString lengths; skipping Execution time vs. LineString length plot.")
        return

    df = pd.DataFrame(rows).sort_values(["benchmark", "series", "length_km"])
    fig = px.scatter(
        df,
        x="length_km",
        y="exec_ms",
        color="series",
        symbol="series",
        labels={"length_km": "LineString length (km)", "exec_ms": "Execution time (ms)", "series": "Data"},
        log_y=True,
        log_x=True,
        trendline="lowess",
        trendline_options=dict(frac=0.2),
    )
    fig.update_layout(
        width=1000,
        height=650,
    )
    _apply_transparent_theme(fig, legend_horizontal=True)
    output_path = _next_output_path("cellstring_delta")
    fig.write_image(output_path)
    print(f"Wrote Execution time vs. LineString length plot to {output_path}")


def plot_stop_area_exec_time(
        benchmarks: List[Dict[str, Any]], meta: Dict[str, Any]
) -> None:
    area_by_stop = _get_stop_area_map(meta)
    if not area_by_stop:
        print("No stop area metadata found; skipping stop-area exec-time plot.")
        return

    rows: List[Dict[str, Any]] = []

    def _add_sample(sample: Dict[str, Any], series:str) -> None:
        stop_id = sample.get("stop_id")
        exec_ms = sample.get("exec_ms")
        if stop_id is None or exec_ms is None:
            return
        area_m2 = area_by_stop.get(int(stop_id))
        if area_m2 is None:
            return
        rows.append(
            {
                "stop_id": stop_id,
                "area_m2": area_m2,
                "exec_ms": exec_ms,
                "series": series,
            }
        )

    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        result = bench.get("result", {})
        st_samples = result.get("st", {}).get("samples", [])
        for sample in st_samples:
            _add_sample(sample, "Polygon")
        for zoom, zoom_result in result.get("cst_results", {}).items():
            for sample in zoom_result.get("samples", []):
                label = zoom or "CellString"
                _add_sample(sample, label)

    if not rows:
        print("No stop-area execution data to plot.")
        return

    df = pd.DataFrame(rows)
    fig = px.scatter(
        df,
        x="area_m2",
        y="exec_ms",
        color="series",
        symbol="series",
        labels={"area_m2": "Stop area (m²)", "exec_ms": "Execution time (ms)"},
        log_y=True,
        log_x=True,
        trendline="lowess",
        trendline_options=dict(frac=0.2),
    )
    fig.update_layout(
        width=1000,
        height=650,
    )
    _apply_transparent_theme(fig, legend_horizontal=True)
    output_path = _next_output_path("stop_area_exec_time")
    fig.write_image(output_path)
    print(f"Wrote Stop Area vs Execution Time plot to {output_path}")


def plot_exec_time_bars(
        time_rows: List[Dict[str, Any]], selected_benchmarks: Optional[List[str]] = None
) -> None:
    if selected_benchmarks:
        selected = set(selected_benchmarks)
        time_rows = [row for row in time_rows if row["benchmark"] in selected]
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
        x="series",
        y="exec_ms",
        color="series",
        labels={"exec_ms": "Execution median (ms)", "series": "Data"},
        log_y=True,
        pattern_shape="series",
        text_auto='.3s',
    )
    fig.update_layout(
    )
    _apply_transparent_theme(fig, with_bar_text=True)
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
                {"benchmark": bench["name"], "zoom": zoom or "n/a", "metric": "False Positives", "count": count}
            )
        for zoom, count in bench["result"]["false_negatives"].items():
            rows.append(
                {"benchmark": bench["name"], "zoom": zoom or "n/a", "metric": "False Negatives", "count": count}
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
        barmode="group",
        labels={"count": "Count", "zoom": "Zoom level"},
        log_y=True,
        pattern_shape="metric",
        text_auto='.3s',
    )
    fig.update_layout(
    )
    _apply_transparent_theme(fig, with_bar_text=True)
    output_path = _next_output_path("false_match_counts")
    fig.write_image(output_path)
    print(f"Wrote False Match Counts plot to {output_path}")


def plot_linestring_containment_pct(benchmarks: List[Dict[str, Any]]) -> None:
    zooms = ["z13", "z17", "z21"]
    rows: List[Dict[str, Any]] = []

    for bench in benchmarks:
        if bench.get("benchmark_type") != "value":
            continue
        name = bench.get("name", "")
        if "LineString containment vs CellString" not in name:
            continue
        variant = "Bresenham" if "Bresenham" in name else "Supercover" if "Supercover" in name else "Unknown"
        values = bench.get("result", {}).get("median_values", {})
        for zoom in zooms:
            pct = values.get(f"{zoom}_not_contained_pct")
            if pct is None:
                continue
            rows.append(
                {
                    "zoom": zoom,
                    "variant": variant,
                    "percentage": pct,
                }
            )
    if not rows:
        print("No LineString containment benchmark data found; skipping plot.")
        return

    df = pd.DataFrame(rows)
    fig = px.bar(
        df,
        x="zoom",
        y="percentage",
        color="variant",
        barmode="group",
        labels={"zoom": "Zoom level", "percentage": "% of trajectories not contained", "variant": "Variant"},
        pattern_shape="variant",
        text_auto='.2f',
    )
    fig.update_layout(
        width=700,
        height=600,
    )
    fig.update_yaxes(
        autorange=False,
        range=[0,100],
    )
    _apply_transparent_theme(fig, with_bar_text=True, left_legend=True)
    output_path = _next_output_path("linestring_containment_pct")
    fig.write_image(output_path)
    print(f"Wrote LineString containment percentage bar-plot to {output_path}")



def plot_crossing_via_exec_times(
        benchmarks: List[Dict[str, Any]],
        zoom_order: Optional[List[str]] = None,
        label_prefix: str = "Crossing via ",
) -> None:
    zooms = zoom_order or ["z13", "z17", "z21"]
    rows: List[Dict[str, Any]] = []

    for bench in benchmarks:
        name = bench.get("name", "")
        if not name.startswith(label_prefix) or bench.get("benchmark_type") != "time":
            continue
        route = name.replace("name", "")
        result = bench.get("result", {})
        st_exec = result.get("st", {}).get("exec_ms_med")
        if st_exec is not None:
            rows.append({"route": route, "series": "LineString", "exec_ms": st_exec})
        for zoom in zooms:
            cst = result.get("cst_results", {}).get(zoom)
            if not cst:
                continue
            exec_ms = cst.get("exec_ms_med")
            if exec_ms is None:
                continue
            rows.append({"route": route, "series": zoom, "exec_ms": exec_ms})

    if not rows:
        print("No crossing via benchmark data found; skipping plot.")
        return

    df = pd.DataFrame(rows)
    fig = px.bar(
        df,
        x="route",
        y="exec_ms",
        color="series",
        barmode="group",
        labels={"route": "Route", "exec_ms": "Execution time (ms)", "series": "Variant"},
        log_y=True,
        pattern_shape="series",
        text_auto='.3s',
    )
    fig.update_layout(
        width=1000,
        height=650,
    )
    _apply_transparent_theme(fig, with_bar_text=True, left_legend=True)
    output_path = _next_output_path("crossing_via_exec_times")
    fig.write_image(output_path)
    print(f"Wrote Crossing Via Execution Times bar-plot to {output_path}")


def run_all_graphs(
        report_path: Path,
        selected_benchmarks: Optional[List[str]] = None,
        selected_plots: Optional[List[str]] = None,
) -> None:
    data = _load_report(report_path)
    benchmarks = _filter_benchmarks(data["benchmarks"], selected_benchmarks)
    if not benchmarks:
        print("No benchmarks matched the requested filters; nothing to plot.")
        return

    plot_filter = {name.lower() for name in selected_plots} if selected_plots else None
    wants = lambda name: plot_filter is None or name.lower() in plot_filter

    length_stats = {entry["label"]: entry for entry in data["meta"].get("trajectory_stats", [])}

    if wants("cellstring_delta"):
        plot_cellstring_delta(benchmarks, data["meta"])

    if wants("stop_area_exec_time"):
        plot_stop_area_exec_time(benchmarks, data["meta"])

    if wants("exec_time_bars"):
        time_rows = _build_time_rows(data["benchmarks"], length_stats)
        plot_exec_time_bars(time_rows, selected_benchmarks)

    if wants("false_match_counts"):
        plot_false_match_counts(benchmarks)

    if wants("linestring_containment_pct"):
        plot_linestring_containment_pct(benchmarks)

    if wants("crossing_via_exec_times"):
        plot_crossing_via_exec_times(benchmarks)


def main(
        path_arg: Optional[str] = None,
        benchmarks: Optional[List[str]] = None,
        plots: Optional[List[str]] = None,
) -> None:
    report_path = _ensure_report_path(path_arg)
    run_all_graphs(report_path, benchmarks, plots)


if __name__ == "__main__":
    args = sys.argv[1:]
    report_arg: Optional[str] = None
    benchmark_filters: List[str] = []
    plot_filters: List[str] = []
    for arg in args:
        if arg.startswith("--benchmark="):
            benchmark_filters.append(arg.split("=", 1)[1])
        elif arg.startswith("--benchmarks="):
            benchmark_filters.extend(
                filter(None, (name.strip() for name in arg.split("=", 1)[1].split(",")))
            )
        elif arg.startswith("--plot="):
            plot_filters.append(arg.split("=", 1)[1])
        elif arg.startswith("--plots="):
            plot_filters.extend(
                filter(None, (name.strip() for name in arg.split("=", 1)[1].split(",")))
            )
        elif report_arg is None:
            report_arg = arg
        else:
            benchmark_filters.append(arg)
    main(report_arg, benchmark_filters or None, plot_filters or None)