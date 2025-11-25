from .intersects_area_benchmark import BENCHMARK as intersects_area_benchmark
from .intersects_traj_benchmark import BENCHMARK as intersects_traj_benchmark
from .hausdorff_distance_benchmark import BENCHMARK as hausdorff_distance_benchmark
from .intersects_with_stop_spatially_and_temporally import BENCHMARK as intersects_with_stop_spatially_and_temporally_benchmark

RUN_PLAN = [
    intersects_traj_benchmark,
    intersects_area_benchmark,
    hausdorff_distance_benchmark,
    intersects_with_stop_spatially_and_temporally_benchmark,
]
