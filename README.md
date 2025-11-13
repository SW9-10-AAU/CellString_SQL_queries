# CellString_SQL_queries
Specific types of queries using CellString


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

### Running Benchmarks
Run the benchmark script with: `python -m benchmarking.main`



#### Sample Output
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
