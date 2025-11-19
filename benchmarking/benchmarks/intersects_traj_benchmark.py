from benchmarking.core import TimeBenchmark

ST_SQL = """
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_ls AS trajA,
    prototype2.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = %s
    AND ST_Intersects(trajA.geom, trajB.geom);
"""

CST_SQL = """
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_cs AS trajA,
    prototype2.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = %s
    AND CST_Intersects(trajA.cellstring_{zoom}, trajB.cellstring_{zoom});
"""

BENCHMARK = TimeBenchmark(
    name="Find trajectories that intersects another trajectory",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    with_trajectory_ids=True,
    zoom_levels=["z13", "z17", "z21"],
)

