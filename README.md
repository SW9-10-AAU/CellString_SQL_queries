# CellString_SQL_queries
Specific types of queries using CellString

## Graphs
To create any graphs, it requires a generated JSON from benchmarks.
1. Create all graphs with `python -m benchmarking.graphs.graph_generation` to generate graphs.
2. Create graphs from a specific JSON file with `python -m benchmarking.graphs.graph_generation benchmarking/benchmark_results/run_xxxxxxxx_xxxxxx.json`
3. Create graphs for a specific benchmark only with `python -m benchmarking.graphs.graph_generation --benchmark="Find trajectories that intersects another trajectory"`

## Benchmarking CellString SQL Queries

### Prerequisites

1. Install PostgreSQL
   - Win: You need to add the PostgreSQL bin folder (which contains libpq.dll) to your system's PATH
2. Create a virtual environment: `python -m venv .venv`
3. Activate environment
   - Win: `.\.venv\Scripts\Activate.ps1`
   - Mac: `source .venv/bin/activate`
4. Install requirements: `pip install -r requirements.txt`
5. Add .env file with your PostgreSQL credentials (see .env.example for reference)

### Setting up a benchmark
It's possible to set up either a `TimeBenchmark` which returns a timing report for two different SQL queries, or a `ValueBenchmark` which runs a query on different trajectory ids to measure a median value, example finding the median _Hausdorff distance_ for 400 trajectories at different zoom levels.


#### TimeBenchmark
1. Create a new benchmark file in `benchmarking/benchmarks/`.
2. Import the class `from benchmarking.core import TimeBenchmark`.
3. Define a SQL query for both ST_ and CST_ versions. For example: 
```python
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
```
4. Define the class instance with parameters:
```python
BENCHMARK = TimeBenchmark(
    name="Find trajectories that intersects an area",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    repeats=2, (OPTIONAL)
    with_trajectory_ids=True, (OPTIONAL)
    zoom_levels=["z13", "z17", "z21"],
    area_ids=[], (Can be used to specify specific area ids to test)
    use_area_ids=True,
    timeout_seconds=120, (OPTIONAL)
)
```
If either `with_trajectory_ids` or `use_area_ids` is set to True, the benchmark will sample trajectory ids or area ids from the database to use as parameters for the query.


#### ValueBenchmark
1. Create a new benchmark file in `benchmarking/benchmarks/`.
2. Import the class `from benchmarking.core import ValueBenchmark`.
3. Define a SQL query that calculates the value to be measured. For example:
```python
SQL = """
SELECT
    cst_hausdorffdistance(cs.cellstring_{zoom}, ls.geom, {zoom_level})
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE
    ls.trajectory_id = %s;
"""
```
4. Define the class instance with parameters:
```python
BENCHMARK = ValueBenchmark(
    name="Hausdorff Distance between CellString and LineString",
    sql=SQL,
    zoom_levels=["z13", "z17", "z21"],
)
```

### Running Benchmarks
1. Make sure your PostgreSQL database is running and accessible.
2. Make sure to have created the necessary benchmark files in `benchmarking/benchmarks/`.
3. Add which benchmarks to run in `benchmarking/benchmarks/__init__.py` to `RUN_PLAN`. For example:
```python
from .intersects_area_benchmark import BENCHMARK as intersects_area_benchmark
from .intersects_traj_benchmark import BENCHMARK as intersects_traj_benchmark
from .hausdorff_distance_benchmark import BENCHMARK as hausdorff_distance_benchmark

RUN_PLAN = [
    intersects_traj_benchmark,
    intersects_area_benchmark,
    hausdorff_distance_benchmark,
]
```
4. Change this line in `benchmarking/main.py` if needed to adjust the number of random trajectories the benchmarks will run on:
```python
cur.execute("SELECT trajectory_id FROM prototype2.trajectory_ls ORDER BY random() LIMIT 5")
```
5. Run the benchmark script with: `python -m benchmarking.main`

### Sample Output
```
--- Intersects benchmark ---
ST_:  exec_ms(median)=1052.918,  wall_ms(median)=1115.13
----------------------------
CST_z13: exec_ms(median)=0.418, wall_ms(median)=6.811
False positives (CST_z13 \ ST_): 14667
False negatives (ST_ \ CST_z13): 1
----------------------------
CST_z17: exec_ms(median)=0.328, wall_ms(median)=4.545
False positives (CST_z17 \ ST_): 6076
False negatives (ST_ \ CST_z17): 13
----------------------------
CST_z21: exec_ms(median)=0.122, wall_ms(median)=3.707
False positives (CST_z21 \ ST_): 1449
False negatives (ST_ \ CST_z21): 98
----------------------------

--- Find intersecting trajectories in an area ---
ST_:  exec_ms(median)=3042.703,  wall_ms(median)=3759.692
----------------------------
CST_z13: exec_ms(median)=0.365, wall_ms(median)=6.417
False positives (CST_z13 \ ST_): 1
False negatives (ST_ \ CST_z13): 0
----------------------------
CST_z17: exec_ms(median)=25.941, wall_ms(median)=34.693
False positives (CST_z17 \ ST_): 1
False negatives (ST_ \ CST_z17): 0
----------------------------
CST_z21: exec_ms(median)=326.956, wall_ms(median)=341.477
False positives (CST_z21 \ ST_): 0
False negatives (ST_ \ CST_z21): 0
----------------------------

--- Hausdorff Distance between CellString and LineString ---
Zoom z13: median value = 0.0146322396
Zoom z17: median value = 0.0011322799
Zoom z21: median value = 0.0000810746
----------------------------

--- Random CellString_z21 trajectory statistics ---
Min length: 1
Median length: 9.0
Max length: 90129
Count of trajectory ids: 200
```

### Benchmark Summary

#### Performance Comparison (ST_ vs CST_ at different zoom levels)

| Scenario                                   | Zoom | ST_ exec_ms | ST_ wall_ms | CST_ exec_ms | CST_ wall_ms | Speedup (exec) | Speedup (wall) | False Positives | False Negatives |
|--------------------------------------------|------|------------:|------------:|-------------:|-------------:|---------------:|---------------:|----------------:|----------------:|
| **Intersects benchmark**                   | -    |    1052.918 |     1115.13 |            - |            - |              - |              - |               - |               - |
|                                            | z13  |           - |           - |        0.418 |        6.811 |      **2519×** |       **164×** |           14667 |               1 |
|                                            | z17  |           - |           - |        0.328 |        4.545 |      **3210×** |       **245×** |            6076 |              13 |
|                                            | z21  |           - |           - |        0.122 |        3.707 |      **8631×** |       **301×** |            1449 |              98 |
| **Find intersecting trajectories in area** | -    |    3042.703 |    3759.692 |            - |            - |              - |              - |               - |               - |
|                                            | z13  |           - |           - |        0.365 |        6.417 |      **8336×** |       **586×** |               1 |               0 |
|                                            | z17  |           - |           - |       25.941 |       34.693 |       **117×** |       **108×** |               1 |               0 |
|                                            | z21  |           - |           - |      326.956 |      341.477 |       **9.3×** |        **11×** |               0 |               0 |

#### Precision Analysis (Hausdorff Distance)

| Zoom Level | Median Hausdorff Distance |
|------------|--------------------------:|
| z13        |              0.0146322396 |
| z17        |              0.0011322799 |
| z21        |              0.0000810746 |

*Note: Lower Hausdorff distance indicates higher precision.*

#### Dataset Characteristics
- **Sample size**: 200 random trajectories
- **CellString_z21 length**: Min=1, Median=9.0, Max=90129 cells
