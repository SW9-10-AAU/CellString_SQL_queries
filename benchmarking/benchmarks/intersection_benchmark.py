from benchmarking.core import Benchmark

ST_SQL = """
SELECT
    traj.trajectory_id,
    area.area_id,
    ST_Intersection(traj.geom, area.geom) AS intersection
FROM
    prototype1.trajectory_ls AS traj,
    benchmark.area_poly AS area
WHERE area.area_id = 2
    AND ST_Intersects(traj.geom, area.geom);
"""

CST_SQL = """
SELECT
    traj.trajectory_id,
    area.area_id,
    CST_Intersection(traj.cellstring, area.cellstring) AS intersection
FROM
    prototype1.trajectory_cs AS traj,
    benchmark.area_cs AS area
WHERE area.area_id = 2
    AND CST_Intersects(traj.cellstring, area.cellstring);
"""

# Example shared parameter for both queries (e.g., a WKT polygon).
PARAMS = (

)

BENCHMARK = Benchmark(
    name="Intersects example (traj vs area)",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    params=PARAMS,
    repeats=5,  # adjust if needed
)

