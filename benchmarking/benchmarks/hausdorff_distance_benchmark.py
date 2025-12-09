from benchmarking.core import ValueBenchmark

SQL = """
SELECT
    cst_hausdorffdistance(cs.cellstring_{zoom}, ls.geom, {zoom_level})
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_supercover_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE
    ls.trajectory_id = %s;
"""

BENCHMARK = ValueBenchmark(
    name="Hausdorff Distance between CellString and LineString",
    sql=SQL,
    zoom_levels=["z13", "z17", "z21"],
    with_trajectory_ids=True,
)
