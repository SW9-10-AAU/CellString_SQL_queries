from benchmarking.core import Benchmark

ST_SQL = """
SELECT
    traj.trajectory_id,
    area.area_id,
    ST_Intersection(traj.geom, area.geom) AS intersection
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.area_poly AS area
WHERE area.area_id = 2
    AND ST_Intersects(traj.geom, area.geom);
"""

CST_SQL = """
SELECT
    traj.trajectory_id,
    area.area_id,
    traj.cellstring_{zoom} & area.cellstring_{zoom} AS intersection
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs AS area
WHERE area.area_id = 2
    AND traj.cellstring_{zoom} && area.cellstring_{zoom};
"""


BENCHMARK = Benchmark(
    name="Find intersecting trajectories in an area",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    repeats=5,
    zoom_levels=["z13", "z17", "z21"],
)

