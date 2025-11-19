from .intersects_area_benchmark import BENCHMARK as intersection_benchmark
from .intersects_traj_benchmark import BENCHMARK as intersects_benchmark

REGISTRY = [
    intersects_benchmark,
    intersection_benchmark,
]
