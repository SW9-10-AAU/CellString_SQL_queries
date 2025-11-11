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



### Sample Output
```
--- Intersects example (traj vs area) ---
ST_:  exec_ms(median)=3032.097,  wall_ms(median)=3253.078
CST_: exec_ms(median)=314.558, wall_ms(median)=330.012
False positives (CST_ \ ST_): 0
False negatives (ST_ \ CST_): 0

--- Intersects long trajectory (small MBR) ---
ST_:  exec_ms(median)=1641.33,  wall_ms(median)=1683.403
CST_: exec_ms(median)=334.837, wall_ms(median)=341.299
False positives (CST_ \ ST_): 0
False negatives (ST_ \ CST_): 0

--- Intersects long trajectory (large MBR) ---
ST_:  exec_ms(median)=4106.542,  wall_ms(median)=4168.307
CST_: exec_ms(median)=2505.811, wall_ms(median)=2521.336
False positives (CST_ \ ST_): 6
False negatives (ST_ \ CST_): 128
```

### Benchmark Summary
| Scenario                                   | ST_ exec_ms (median) | ST_ wall_ms (median) | CST_ exec_ms (median) | CST_ wall_ms (median) | Speedup (ST_ / CST_) | False Positives (CST_ \ ST_) | False Negatives (ST_ \ CST_) |
|--------------------------------------------|----------------------:|----------------------:|----------------------:|----------------------:|--------------------:|------------------------------:|------------------------------:|
| Intersects example (traj vs area)          | 3032.097             | 3253.078             | 314.558              | 330.012              | **9.64×**           | 0                            | 0                            |
| Intersects long trajectory (small MBR)     | 1641.330             | 1683.403             | 334.837              | 341.299              | **4.90×**           | 0                            | 0                            |
| Intersects long trajectory (large MBR)     | 4106.542             | 4168.307             | 2505.811             | 2521.336             | **1.64×**           | 6                            | 128                          |

