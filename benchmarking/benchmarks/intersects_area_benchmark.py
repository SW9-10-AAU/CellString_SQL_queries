from benchmarking.core import TimeBenchmark

ST_SQL = """
SELECT
    traj.trajectory_id
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.area_poly AS area
WHERE area.area_id = %s
    AND ST_Intersects(traj.geom, area.geom);
"""

CST_SQL = """
SELECT
    traj.trajectory_id
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs AS area
WHERE area.area_id = %s
    AND CST_Intersects(traj.cellstring_{zoom}, area.cellstring_{zoom});
"""


BENCHMARK = TimeBenchmark(
    name="Find trajectories that intersects an area",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    repeats=2,
    zoom_levels=["z13", "z17", "z21"],
    use_area_ids=True,
    timeout_seconds=20,
)

