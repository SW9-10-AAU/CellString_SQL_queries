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
ST_:  exec_ms(median)=1084.367,  wall_ms(median)=1132.21
----------------------------
CST_z13: exec_ms(median)=0.451, wall_ms(median)=7.123
False positives (CST_z13 \ ST_): 11358
False negatives (ST_ \ CST_z13): 1
----------------------------
CST_z17: exec_ms(median)=0.328, wall_ms(median)=4.509
False positives (CST_z17 \ ST_): 4434
False negatives (ST_ \ CST_z17): 5
----------------------------
CST_z21: exec_ms(median)=0.14, wall_ms(median)=4.131
False positives (CST_z21 \ ST_): 787
False negatives (ST_ \ CST_z21): 47
----------------------------

--- Random trajectory Statistics ---
Min: 1
Median: 10.5
Max: 98819
```

### Benchmark Summary
| Scenario                                   | ST_ exec_ms (median) | ST_ wall_ms (median) | CST_ exec_ms (median) | CST_ wall_ms (median) | Speedup (ST_ / CST_) | False Positives (CST_ \ ST_) | False Negatives (ST_ \ CST_) |
|--------------------------------------------|----------------------:|----------------------:|----------------------:|----------------------:|--------------------:|------------------------------:|------------------------------:|
| Intersects example (traj vs area)          | 3032.097             | 3253.078             | 314.558              | 330.012              | **9.64×**           | 0                            | 0                            |
| Intersects long trajectory (small MBR)     | 1641.330             | 1683.403             | 334.837              | 341.299              | **4.90×**           | 0                            | 0                            |
| Intersects long trajectory (large MBR)     | 4106.542             | 4168.307             | 2505.811             | 2521.336             | **1.64×**           | 6                            | 128                          |

