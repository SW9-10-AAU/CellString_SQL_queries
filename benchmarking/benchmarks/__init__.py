from .intersection_benchmark import BENCHMARK as intersection
from .intersects_long_traj_small_mbr import BENCHMARK as intersects_long_traj_small_mbr
from .intersects_long_traj_large_mbr import BENCHMARK as intersects_long_traj_large_mbr

REGISTRY = [
    intersection,
    intersects_long_traj_small_mbr,
    intersects_long_traj_large_mbr,
]
