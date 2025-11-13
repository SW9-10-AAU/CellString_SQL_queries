from benchmarking.core import Benchmark

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
    AND trajA.cellstring_{zoom} && trajB.cellstring_{zoom};
"""

BENCHMARK = Benchmark(
    name="Intersects benchmark",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    with_trajectory_ids=True,
    zoom_levels=["z13", "z17", "z21"],
)

