import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

import pandas as pd
import plotly.express as px


OUTPUT_DIR = Path("benchmarking/graphs/output")
SAFE = px.colors.qualitative.Safe
ZOOM_ORDER = ["z13", "z17", "z21"]
SERIES_COLOR_MAP = {
    "LineString": SAFE[0],
    "z13": SAFE[1],
    "z17": SAFE[2],
    "z21": SAFE[3],
}
SERIES_SYMBOL_MAP = {
    "LineString": "circle",
    "z13": "square",
    "z17": "diamond",
    "z21": "x",
}


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


def _get_cardinality_map(cards: Dict[str, Any], zoom: str) -> Dict[int, int]:
    if not cards or not zoom:
        return {}
    zoom_card = cards.get(zoom) or cards.get(str(zoom))
    if not isinstance(zoom_card, dict):
        return {}
    normalized: Dict[int, int] = {}
    for traj_id, count in zoom_card.items():
        try:
            normalized[int(traj_id)] = int(count)
        except (TypeError, ValueError):
            continue
    return normalized


def _select_trajectory_cardinality_source(meta: Dict[str, Any], bench_name: str) -> Dict[str, Any]:
    label = (bench_name or "").lower()
    if "supercover" in label:
        return meta.get("trajectory_supercover_cardinalities") or {}
    if "bresenham" in label:
        return meta.get("trajectory_cardinalities") or {}
    return meta.get("trajectory_cardinalities") or {}


def _get_linestring_length_map(meta: Dict[str, Any]) -> Dict[int, float]:
    length_map: Dict[int, float] = {}
    candidates = [
        ("trajectory_lengths_km", 1.0),
        ("trajectory_linestring_lengths_km", 1.0),
        ("trajectory_lengths_m", 0.001),
        ("trajectory_linestring_lengths_m", 0.001),
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


def _get_linestring_mbr_area_map(meta: Dict[str, Any]) -> Dict[int, float]:
    area_map: Dict[int, float] = {}
    candidates = [
        ("trajectory_linestring_mbr_area_m2", 1_000_000.0**-1),
        ("trajectory_mbr_area_m2", 1_000_000.0**-1),
        ("trajectory_linestring_mbr_area_km2", 1.0),
        ("trajectory_mbr_area_km2", 1.0),
    ]
    for key, scale in candidates:
        values = meta.get(key)
        if not isinstance(values, dict):
            continue
        for traj_id, raw in values.items():
            if raw is None:
                continue
            try:
                area_map[int(traj_id)] = float(raw) * scale
            except (TypeError, ValueError):
                continue
        if area_map:
            break
    return area_map


def _get_stop_cardinality_map(meta: Dict[str, Any], zoom: str) -> Dict[int, int]:
    cards = meta.get("stop_cardinalities") or {}
    zoom_card = cards.get(zoom) or cards.get(str(zoom))
    if not zoom_card:
        return {}
    if isinstance(zoom_card, dict):
        normalized: Dict[int, int] = {}
        for stop_id, count in zoom_card.items():
            try:
                normalized[int(stop_id)] = int(count)
            except (TypeError, ValueError):
                continue
        return normalized
    if isinstance(zoom_card, list):
        stop_ids = meta.get("stop_ids") or []
        if len(stop_ids) != len(zoom_card):
            return {}
        normalized = {}
        for stop_id, count in zip(stop_ids, zoom_card):
            try:
                normalized[int(stop_id)] = int(count)
            except (TypeError, ValueError):
                continue
        return normalized
    return {}


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
        font_size=25,
        font_weight=550,
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
        tickfont_size=25,
    )
    fig.update_yaxes(
        showgrid=False,
        showline=True,
        linewidth=2,
        linecolor="black",
        ticks="inside",
        mirror=True,
        minorloglabels="complete",
        tickfont_size=25,
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
        color_discrete_map=SERIES_COLOR_MAP,
        symbol="series",
        symbol_map=SERIES_SYMBOL_MAP,
        category_orders={"series": ["LineString", *ZOOM_ORDER]},
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


def plot_cellstring_length(benchmarks: List[Dict[str, Any]], meta: Dict[str, Any]) -> None:
    if not any(
        isinstance(meta.get(key), dict) and meta.get(key)
        for key in (
            "trajectory_cardinalities",
            "trajectory_supercover_cardinalities",
        )
    ):
        print("No CellString cardinality data found in the report; skipping Execution time vs. CellString length plot.")
        return

    rows: List[Dict[str, Any]] = []
    LINESTRING_MEDIAN_EXEC_MS = 758.638

    def _collect_samples(samples: List[Dict[str, Any]], zoom: str, bench_name: str, card_source: Dict[str, Any]) -> None:
        if not zoom or not card_source:
            return
        card_map = _get_cardinality_map(card_source, zoom)
        if not card_map:
            return
        for sample in samples or []:
            traj_id = sample.get("trajectory_id")
            exec_ms = sample.get("exec_ms")
            if traj_id is None or exec_ms is None:
                continue
            cell_count = card_map.get(int(traj_id))
            if cell_count is None:
                continue
            rows.append(
                {
                    "benchmark": bench_name,
                    "zoom": zoom,
                    "trajectory_id": traj_id,
                    "cell_count": cell_count,
                    "exec_ms": exec_ms,
                }
            )

    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        result = bench["result"]
        card_source = _select_trajectory_cardinality_source(meta, bench.get("name", ""))
        for zoom, cst in result.get("cst_results", {}).items():
            _collect_samples(cst.get("samples", []), zoom, bench["name"], card_source)

    if not rows:
        print("No benchmark samples with CellString cardinality; skipping Execution time vs. CellString length plot.")
        return

    df = pd.DataFrame(rows).sort_values(["benchmark", "zoom", "cell_count"])
    fig = px.scatter(
        df,
        x="cell_count",
        y="exec_ms",
        color="zoom",
        color_discrete_map=SERIES_COLOR_MAP,
        symbol="zoom",
        symbol_map=SERIES_SYMBOL_MAP,
        category_orders={"zoom": ZOOM_ORDER},
        labels={"cell_count": "CellString length (# of cells)", "exec_ms": "Execution time (ms)", "zoom": "Zoom level"},
        log_y=True,
        log_x=True,
        trendline="lowess",
        trendline_options=dict(frac=0.2),
    )
    fig.update_layout(
        width=1000,
        height=650,
    )
    fig.update_xaxes(
        tickangle=45,
    )
    fig.add_hline(
        y=LINESTRING_MEDIAN_EXEC_MS,
        line_dash="dot",
        line_color="black",
    )
    fig.add_annotation(
        x=0.02,
        xref="paper",
        y=0.97,
        yref="paper",
        text=f"LineString median ({LINESTRING_MEDIAN_EXEC_MS:.3f} ms)",
        bgcolor="rgba(255,255,255,0.9)",
        font=dict(color="black", size=26),
        showarrow=False,
        xanchor="left",
        yanchor="top",
    )
    _apply_transparent_theme(fig, legend_horizontal=True)
    output_path = _next_output_path("cellstring_length")
    fig.write_image(output_path)
    print(f"Wrote Execution time vs. CellString length plot to {output_path}")


def plot_linestring_mbr_exec_time(benchmarks: List[Dict[str, Any]], meta: Dict[str, Any]) -> None:
    area_map = _get_linestring_mbr_area_map(meta)
    if not area_map:
        print("No LineString MBR area data found in the report; skipping MBR-area plot.")
        return

    rows: List[Dict[str, Any]] = []

    def _collect(samples: List[Dict[str, Any]], series: str, bench_name: str) -> None:
        for sample in samples or []:
            traj_id = sample.get("trajectory_id")
            exec_ms = sample.get("exec_ms")
            if traj_id is None or exec_ms is None:
                continue
            area_km2 = area_map.get(int(traj_id))
            if area_km2 is None or area_km2 <= 0:
                continue
            rows.append(
                {
                    "benchmark": bench_name,
                    "series": series,
                    "trajectory_id": traj_id,
                    "area_km2": area_km2,
                    "exec_ms": exec_ms,
                }
            )

    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        result = bench.get("result", {})
        _collect(result.get("st", {}).get("samples", []), "LineString", bench["name"])
        for zoom, cst in result.get("cst_results", {}).items():
            label = zoom or "CellString"
            _collect(cst.get("samples", []), label, bench["name"])

    if not rows:
        print("No benchmark samples with LineString MBR areas; skipping MBR-area plot.")
        return

    df = pd.DataFrame(rows).sort_values(["benchmark", "series", "area_km2"])
    fig = px.scatter(
        df,
        x="area_km2",
        y="exec_ms",
        color="series",
        color_discrete_map=SERIES_COLOR_MAP,
        symbol="series",
        symbol_map=SERIES_SYMBOL_MAP,
        category_orders={"series": ["LineString", *ZOOM_ORDER]},
        labels={"area_km2": "LineString MBR area (km²)", "exec_ms": "Execution time (ms)", "series": "Data"},
        log_y=True,
        log_x=True,
        trendline="lowess",
        trendline_options=dict(frac=0.2),
    )
    fig.update_layout(width=1000, height=650)
    _apply_transparent_theme(fig, legend_horizontal=True)
    output_path = _next_output_path("linestring_mbr_exec_time")
    fig.write_image(output_path)
    print(f"Wrote Execution time vs. LineString MBR area plot to {output_path}")


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
        color_discrete_map=SERIES_COLOR_MAP,
        symbol="series",
        symbol_map=SERIES_SYMBOL_MAP,
        category_orders={"zoom": ZOOM_ORDER},
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
    fig.update_xaxes(
        tickangle=45,
    )
    _apply_transparent_theme(fig, legend_horizontal=True)
    output_path = _next_output_path("stop_area_exec_time")
    fig.write_image(output_path)
    print(f"Wrote Stop Area vs Execution Time plot to {output_path}")


def plot_stop_cellstring_length_exec_time(
        benchmarks: List[Dict[str, Any]], meta: Dict[str, Any]
) -> None:
    rows: List[Dict[str, Any]] = []

    def _add_sample(sample:Dict[str, Any], series: str, card_map: Dict[int, int]) -> None:
        stop_id = sample.get("stop_id")
        exec_ms = sample.get("exec_ms")
        if stop_id is None or exec_ms is None:
            return
        cell_count = card_map.get(int(stop_id))
        if cell_count is None:
            return
        rows.append(
            {
                "stop_id": stop_id,
                "cell_count": cell_count,
                "exec_ms": exec_ms,
                "series": series,
            }
        )

    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        result = bench.get("result", {})
        for zoom, zoom_result in result.get("cst_results", {}).items():
            if not zoom:
                continue
            card_map = _get_stop_cardinality_map(meta, zoom)
            if not card_map:
                continue
            for sample in zoom_result.get("samples", []):
                _add_sample(sample, zoom, card_map)

    if not rows:
        print("No stop CellString execution data to plot.")
        return

    df = pd.DataFrame(rows)
    fig = px.scatter(
        df,
        x="cell_count",
        y="exec_ms",
        color="series",
        color_discrete_map=SERIES_COLOR_MAP,
        symbol="series",
        symbol_map=SERIES_SYMBOL_MAP,
        category_orders={"zoom": ZOOM_ORDER},
        labels={"cell_count": "CellString length (# of cells)", "exec_ms": "Execution time (ms)", "series": "Zoom"},
        log_y=True,
        log_x=True,
        trendline="lowess",
        trendline_options=dict(frac=0.2),
    )
    fig.update_layout(width=1000, height=650)
    _apply_transparent_theme(fig, legend_horizontal=True)
    output_path = _next_output_path("stop_cellstring_length")
    fig.write_image(output_path)
    print(f"Wrote Stop CellString length vs Execution Time plot to {output_path}")


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
            bars.append({"benchmark": bench, "series": "LineString", "exec_ms": row["st_exec_ms"]})
            emitted_st[bench] = True
        bars.append({"benchmark": bench, "series": f"{row['zoom']}", "exec_ms": row["cst_exec_ms"]})
    df = pd.DataFrame(bars)
    fig = px.bar(
        df,
        x="series",
        y="exec_ms",
        color="series",
        color_discrete_sequence=px.colors.qualitative.Safe,
        labels={"exec_ms": "Execution median (ms)", "series": "Data"},
        log_y=True,
        pattern_shape="series",
        text_auto='.3f',
    )
    fig.update_traces(texttemplate="%{y:.3f} ms")
    fig.update_layout(
        showlegend=False
    )
    _apply_transparent_theme(fig, with_bar_text=True)
    output_path = _next_output_path("exec_time_bars")
    fig.write_image(output_path)
    print(f"Wrote Execution time bars to {output_path}")


def plot_false_match_counts(benchmarks: List[Dict[str, Any]]) -> None:
    def _normalize_zoom_label(raw_zoom: Optional[str]) -> str:
        if raw_zoom in (None, "", "LineString", "linestring", "st"):
            return "LineString"
        return str(raw_zoom)

    metric_totals: Dict[str, Dict[str, float]] = {}
    for bench in benchmarks:
        if bench.get("benchmark_type") != "time":
            continue
        result = bench.get("result", {})
        for metric_key, metric_label in (
            ("false_positives", "False Positives"),
            ("false_negatives", "False Negatives"),
        ):
            counts = result.get(metric_key)
            if not isinstance(counts, dict):
                continue
            bucket = metric_totals.setdefault(metric_label, {})
            for zoom, count in counts.items():
                if count is None:
                    continue
                try:
                    value = float(count)
                except (TypeError, ValueError):
                    continue
                label = _normalize_zoom_label(zoom)
                bucket[label] = bucket.get(label, 0.0) + value

    rows: List[Dict[str, Any]] = []
    for metric, zoom_counts in metric_totals.items():
        baseline = zoom_counts.get("LineString")
        if baseline in (None, 0):
            continue
        for zoom, total in zoom_counts.items():
            if zoom == "LineString":
                continue
            pct_delta = (total / baseline) * 100
            rows.append({"zoom": zoom, "metric": metric, "pct_delta": pct_delta})

    if not rows:
        print("No relative false positive/negative data to plot.")
        return

    df = pd.DataFrame(rows)
    zoom_order = sorted(df["zoom"].unique(), key=lambda z: (len(z), z))
    df["zoom"] = pd.Categorical(df["zoom"], categories=zoom_order, ordered=True)

    fig = px.bar(
        df,
        x="zoom",
        y="pct_delta",
        color="metric",
        color_discrete_sequence=px.colors.qualitative.Safe,
        barmode="group",
        labels={"zoom": "Zoom level", "pct_delta": "% of LineString", "metric": "Metric"},
        pattern_shape="metric",
        text_auto='.1f',
    )
    fig.update_traces(texttemplate="%{y:.1f}%")
    fig.update_layout(width=700, height=600)
    y_min = 0
    y_max = max(df["pct_delta"].max(), 0) + 5
    fig.update_yaxes(
        autorange=False,
        range=[y_min,y_max],
        ticksuffix="%",
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
        color_discrete_sequence=px.colors.qualitative.Safe,
        barmode="group",
        labels={"zoom": "Zoom level", "percentage": "% of trajectories not contained", "variant": "Variant"},
        pattern_shape="variant",
        text_auto='.1f',
    )
    fig.update_traces(texttemplate="%{y:.1f}%")
    fig.update_layout(
        width=700,
        height=600,
    )
    fig.update_yaxes(
        autorange=False,
        range=[0,105],
        ticksuffix="%",
    )
    _apply_transparent_theme(fig, with_bar_text=True, left_legend=True)
    output_path = _next_output_path("linestring_containment_pct")
    fig.write_image(output_path)
    print(f"Wrote LineString containment percentage bar-plot to {output_path}")


def plot_crossing_via_exec_times(
        benchmarks: List[Dict[str, Any]],
        zoom_order: Optional[List[str]] = None,
        label_prefix: str = "Skagen",
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
        color_discrete_sequence=px.colors.qualitative.Safe,
        barmode="group",
        labels={"route": "Route", "exec_ms": "Execution time (ms)", "series": "Variant"},
        log_y=True,
        pattern_shape="series",
        text_auto='.2f',
    )
    fig.update_traces(texttemplate="%{y:.2f} ms")
    fig.update_layout(
        width=1000,
        height=650,
    )
    _apply_transparent_theme(fig, with_bar_text=True)
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

    if wants("cellstring_length"):
        plot_cellstring_length(benchmarks, data["meta"])

    if wants("linestring_mbr_exec_time"):
        plot_linestring_mbr_exec_time(benchmarks, data["meta"])

    if wants("stop_area_exec_time"):
        plot_stop_area_exec_time(benchmarks, data["meta"])

    if wants("stop_cellstring_length_exec_time"):
        plot_stop_cellstring_length_exec_time(benchmarks, data["meta"])

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