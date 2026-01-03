from benchmarking.core import TimeBenchmark

ZOOM_LEVELS = ["z13", "z17", "z21"]

ST_SQL = """
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM prototype2.trajectory_ls AS traj,
     benchmark.crossing_ls AS crossingA,
     benchmark.crossing_ls AS crossingB,
     benchmark.crossing_ls AS crossingC
WHERE crossingA.crossing_id = %s
  AND crossingB.crossing_id = %s
  AND crossingC.crossing_id = %s
  AND ST_Intersects(traj.geom, crossingA.geom)
  AND ST_Intersects(traj.geom, crossingB.geom)
  AND ST_Intersects(traj.geom, crossingC.geom);
"""

CST_SQL = """
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM prototype2.trajectory_supercover_cs AS traj,
     benchmark.crossing_cs AS crossingA,
     benchmark.crossing_cs AS crossingB,
     benchmark.crossing_cs AS crossingC
WHERE crossingA.crossing_id = %s
  AND crossingB.crossing_id = %s
  AND crossingC.crossing_id = %s
  AND CST_Intersects(traj.cellstring_{zoom}, crossingA.cellstring_{zoom})
  AND CST_Intersects(traj.cellstring_{zoom}, crossingB.cellstring_{zoom})
  AND CST_Intersects(traj.cellstring_{zoom}, crossingC.cellstring_{zoom});
"""


def build_via_benchmark(label: str, crossings: tuple[int, int, int]) -> TimeBenchmark:
    return TimeBenchmark(
        name=f"{label}",
        st_sql=ST_SQL,
        cst_sql=CST_SQL,
        params=crossings,
        zoom_levels=ZOOM_LEVELS,
        repeats=5,
    )


CROSSING_VIA_BENCHMARKS = [
    build_via_benchmark("Skagen-Storebælt-Bornholm", (1, 2, 4)),
    build_via_benchmark("Skagen-Kattegat-Storebælt", (1, 6, 2))
]