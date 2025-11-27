from .intersects_area_benchmark import BENCHMARK as intersects_area_benchmark
from .intersects_traj_benchmark_bresenham import BENCHMARK as intersects_traj_benchmark_bresenham
from .intersects_traj_benchmark_supercover import BENCHMARK as intersects_traj_benchmark_supercover
from .hausdorff_distance_benchmark import BENCHMARK as hausdorff_distance_benchmark
from .intersects_with_stop_spatially_and_temporally import BENCHMARK as intersects_with_stop_spatially_and_temporally_benchmark
from .via_query_benchmark import CROSSING_VIA_BENCHMARKS

RUN_PLAN = [
    intersects_area_benchmark,
    intersects_traj_benchmark_bresenham,
    intersects_traj_benchmark_supercover,
    hausdorff_distance_benchmark,
    intersects_with_stop_spatially_and_temporally_benchmark,
    *CROSSING_VIA_BENCHMARKS,
]
