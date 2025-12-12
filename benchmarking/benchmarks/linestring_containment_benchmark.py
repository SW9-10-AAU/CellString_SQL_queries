from benchmarking.core import ValueBenchmark

def _build_sql(cellstring_table: str) -> str:
    return f"""
WITH containment AS (
    SELECT
        ls.trajectory_id,
        NOT ST_Contains(CST_AsMultiPolygon(cs.cellstring_z13, 13), ls.geom) AS z13_violation,
        NOT ST_Contains(CST_AsMultiPolygon(cs.cellstring_z17, 17), ls.geom) AS z17_violation,
        NOT ST_Contains(CST_AsMultiPolygon(cs.cellstring_z21, 21), ls.geom) AS z21_violation
    FROM prototype2.trajectory_ls ls
    JOIN {cellstring_table} cs
        ON ls.trajectory_id = cs.trajectory_id
    WHERE ls.trajectory_id = ANY(%(trajectory_ids)s)
)
SELECT label, value
FROM (
    SELECT
        'z13_not_contained_pct' AS label,
        100.0 * SUM(CASE WHEN z13_violation THEN 1 ELSE 0 END)::double precision / NULLIF(COUNT(*), 0) AS value
    FROM containment
    UNION ALL
    SELECT
        'z17_not_contained_pct',
        100.0 * SUM(CASE WHEN z17_violation THEN 1 ELSE 0 END)::double precision / NULLIF(COUNT(*), 0)
    FROM containment
    UNION ALL
    SELECT
        'z21_not_contained_pct',
        100.0 * SUM(CASE WHEN z21_violation THEN 1 ELSE 0 END)::double precision / NULLIF(COUNT(*), 0)
    FROM containment
) AS per_zoom
WHERE value IS NOT NULL;
"""


LINESTRING_CONTAINMENT_BENCHMARKS = [
    ValueBenchmark(
        name="LineString containment vs CellString - Bresenham",
        sql=_build_sql("prototype2.trajectory_cs"),
        with_trajectory_ids=True,
    ),
    ValueBenchmark(
        name="LineString containment vs CellString - Supercover",
        sql=_build_sql("prototype2.trajectory_supercover_cs"),
        with_trajectory_ids=True,
    ),
]