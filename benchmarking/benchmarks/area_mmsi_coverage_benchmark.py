from benchmarking.core import ValueBenchmark

ZOOM_LEVELS = ["z13", "z17", "z21"]
TRAJECTORY_TABLE = "prototype2.trajectory_supercover_cs"

SQL_TEMPLATE = f"""
WITH area AS (
    SELECT
        cellstring_{{zoom}} AS cellstring,
        %s::int AS area_id
    FROM benchmark.area_cs
    WHERE area_id = %s
)
SELECT
    area.area_id,
    coverage.mmsi,
    coverage.coverage_percent
FROM area
CROSS JOIN LATERAL CST_Coverage_ByMMSI(
    '{TRAJECTORY_TABLE}'::regclass,
    {{zoom_level}},
    area.cellstring
) AS coverage
ORDER BY coverage.coverage_percent DESC;
"""


def build_area_coverage_benchmark(area_id: int) -> ValueBenchmark:
    return ValueBenchmark(
        name=f"MMSI Coverage - Area {area_id}",
        sql=SQL_TEMPLATE,
        zoom_levels=ZOOM_LEVELS,
        params=(area_id, area_id),
        capture_rows=True,
        row_field_names=["area_id", "mmsi", "coverage_percent"],
    )


AREA_MMSI_COVERAGE_BENCHMARKS = [build_area_coverage_benchmark(area_id) for area_id in (2, 3)]

