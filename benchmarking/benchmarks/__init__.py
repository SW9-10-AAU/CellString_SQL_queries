from .intersects_area_benchmark import BENCHMARK as intersects_area_benchmark
from .intersects_traj_benchmark_bresenham import BENCHMARK as intersects_traj_benchmark_bresenham
from .intersects_traj_benchmark_supercover import BENCHMARK as intersects_traj_benchmark_supercover
from .hausdorff_distance_benchmark import BENCHMARK as hausdorff_distance_benchmark

RUN_PLAN = [
    intersects_traj_benchmark_bresenham,
    intersects_traj_benchmark_supercover,
]
