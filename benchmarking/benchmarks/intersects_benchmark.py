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
    AND CST_Intersects(trajA.cellstring_z21, trajB.cellstring_z21);
"""

# Example shared parameter for both queries (e.g., a WKT polygon).
PARAMS = (

)

BENCHMARK = Benchmark(
    name="Intersects benchmark",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    params=PARAMS,
    repeats=5,  # adjust if needed
    per_trajectory=True
)

