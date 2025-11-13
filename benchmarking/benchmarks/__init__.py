from .intersection_benchmark import BENCHMARK as intersection_benchmark
from .intersects_benchmark import BENCHMARK as intersects_benchmark
from .hausdorff_distance_benchmark import BENCHMARK as hausdorff_distance_benchmark

RUN_PLAN = [
    intersects_benchmark,
    intersection_benchmark,
    hausdorff_distance_benchmark,
]
