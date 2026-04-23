-- Cellstring queries for benchmark

--------------------------------------------------------------------------------------------------------------
-- GLOBAL SCRIPT VARIABLES (Run these once before your queries)
--------------------------------------------------------------------------------------------------------------
-- [VARIABLE] Set your area_id here
SET VARIABLE area_id = 1;

-- [VARIABLE] Uncomment ONE of the intervals below for your time range:

-- 1_day
SET VARIABLE t_start = TIMESTAMP '2025-12-01 00:00:00.000';
SET VARIABLE t_end   = TIMESTAMP '2025-12-02 00:00:00.000';

-- 1_week
--SET VARIABLE t_start = TIMESTAMP '2025-12-01 00:00:00.000';
--SET VARIABLE t_end   = TIMESTAMP '2025-12-08 00:00:00.000';

-- 1_month
--SET VARIABLE t_start = TIMESTAMP '2025-12-01 00:00:00.000';
--SET VARIABLE t_end   = TIMESTAMP '2026-01-01 00:00:00.000';


--------------------------------------------------------------------------------------------------------------
-- 1. Spatial Range
--------------------------------------------------------------------------------------------------------------
-- area 1 = 630 rows
-- area 2 = 2892 rows
-- area 3 = 4622 rows
WITH selected_area AS (
    SELECT area_id, cell_z21
    FROM db_design1_v3.area_cs
    WHERE area_id = getvariable('area_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, a.area_id, 'trajectory' AS source
FROM db_design1_v3.trajectory_cs t
JOIN selected_area a ON t.cell_z21 = a.cell_z21

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, a.area_id, 'stop' AS source
FROM db_design1_v3.stop_cs s
JOIN selected_area a ON s.cell_z21 = a.cell_z21;


--------------------------------------------------------------------------------------------------------------
-- 2. Temporal Range
--------------------------------------------------------------------------------------------------------------
--1d = 6863
--1w = 43515 (24468traj + 19047stop)
--1m = 190.313 (104613traj + 85700stop)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM db_design1_v3.trajectory_cs t
WHERE t.ts BETWEEN getvariable('t_start') AND getvariable('t_end')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM db_design1_v3.stop_cs s
WHERE s.ts_start <= getvariable('t_end')
  AND s.ts_end >= getvariable('t_start');

--------------------------------------------------------------------------------------------------------------
-- 3. Spatio-temporal Range
--------------------------------------------------------------------------------------------------------------
--1d/area1 = return 17 rows
--1d/area2 = return 72 rows
--1d/area3 = return 122 rows
--1w/area1 = return 107 rows
--1w/area2 = return 533 rows
--1w/area3 = return 901 rows
--1m/area1 = return 494 rows
--1m/area2 = return 2298 rows
--1m/area3 = return 3655 rows
EXPLAIN ANALYZE
WITH selected_area AS (
    SELECT area_id, cell_z21
    FROM db_design1_v3.area_cs
    WHERE area_id = getvariable('area_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, a.area_id, 'trajectory' AS source
FROM db_design1_v3.trajectory_cs t
JOIN selected_area a ON t.cell_z21 = a.cell_z21
WHERE t.ts BETWEEN getvariable('t_start') AND getvariable('t_end')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, a.area_id, 'stop' AS source
FROM db_design1_v3.stop_cs s
JOIN selected_area a ON s.cell_z21 = a.cell_z21
WHERE s.ts_start <= getvariable('t_end')
  AND s.ts_end >= getvariable('t_start');

--------------------------------------------------------------------------------------------------------------
--Spatio-temporal Join (“ID Temporal”)
--------------------------------------------------------------------------------------------------------------
SET VARIABLE target_traj_id = 2;
SET VARIABLE target_t_start = (SELECT MIN(ts) FROM db_design1_v3.trajectory_cs WHERE trajectory_id = getvariable('target_traj_id'));
SET VARIABLE target_t_end   = (SELECT MAX(ts) FROM db_design1_v3.trajectory_cs WHERE trajectory_id = getvariable('target_traj_id'));

WITH target_cells AS (
    SELECT DISTINCT cell_z21, mmsi
    FROM db_design1_v3.trajectory_cs
    WHERE trajectory_id = getvariable('target_traj_id')
)
SELECT DISTINCT c.mmsi, c.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM db_design1_v3.trajectory_cs c
JOIN target_cells t ON c.cell_z21 = t.cell_z21
WHERE c.mmsi <> t.mmsi
  AND c.ts BETWEEN getvariable('target_t_start') AND getvariable('target_t_end')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM db_design1_v3.stop_cs s
JOIN target_cells t ON s.cell_z21 = t.cell_z21
WHERE s.mmsi <> t.mmsi
  AND s.ts_start <= getvariable('target_t_end')
  AND s.ts_end >= getvariable('target_t_start');


-- linestring equivalent
WITH target_info AS (
    SELECT DISTINCT cell_z21, mmsi
    FROM db_design1_v3.trajectory_cs
    WHERE trajectory_id = getvariable('target_traj_id')
),
spatial_matches AS (
    SELECT DISTINCT c.trajectory_id, c.mmsi
    FROM db_design1_v3.trajectory_cs c
    JOIN target_info t ON c.cell_z21 = t.cell_z21
    WHERE c.mmsi <> t.mmsi
),
candidate_times AS (
    SELECT c.trajectory_id, MIN(c.ts) AS cand_t_start, MAX(c.ts) AS cand_t_end
    FROM db_design1_v3.trajectory_cs c
    JOIN spatial_matches sm ON c.trajectory_id = sm.trajectory_id
    GROUP BY c.trajectory_id
)
SELECT sm.mmsi, sm.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM spatial_matches sm
JOIN candidate_times ct ON sm.trajectory_id = ct.trajectory_id
WHERE ct.cand_t_start <= getvariable('target_t_end')
  AND ct.cand_t_end >= getvariable('target_t_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM db_design1_v3.stop_cs s
JOIN target_info t ON s.cell_z21 = t.cell_z21
WHERE s.mmsi <> t.mmsi
  AND s.ts_start <= getvariable('target_t_end')
  AND s.ts_end >= getvariable('target_t_start');


--------------------------------------------------------------------------------------------------------------
--Via Query (Spatial Join)
--------------------------------------------------------------------------------------------------------------
--Skagen-Storebælt-Bornholm
SELECT
    t.trajectory_id,
    t.mmsi
FROM db_design1_v3.trajectory_cs t
JOIN db_design1_v3.crossing_cs c ON t.cell_z21 = c.cell_z21
WHERE c.name IN ('Skagen', 'Storebælt', 'Bornholm')
GROUP BY t.trajectory_id, t.mmsi
-- Hit all 3 unique crossings
HAVING COUNT(DISTINCT c.crossing_id) = 3;

--Skagen-Kattegat-Storebælt
SELECT
    t.trajectory_id,
    t.mmsi
FROM db_design1_v3.trajectory_cs t
JOIN db_design1_v3.crossing_cs c ON t.cell_z21 = c.cell_z21
WHERE c.name IN ('Skagen', 'Kattegat', 'Storebælt')
GROUP BY t.trajectory_id, t.mmsi
-- Hit all 3 unique crossings
HAVING COUNT(DISTINCT c.crossing_id) = 3;


--Actual join on z? cells (gives false positives)
WITH
extracted_crossing_z13 AS (
    SELECT DISTINCT
        crossing_id,
        CS_GetParentCellId(cell_z21, 21, 13) AS cell_z21
    FROM db_design1_v3.crossing_cs
    WHERE crossing_id IN (2, 3, 5)
),

extracted_trajectory_z13 AS (
    SELECT DISTINCT
        trajectory_id,
        mmsi,
        CS_GetParentCellId(cell_z21, 21, 13) AS cell_z21
    FROM db_design1_v3.trajectory_cs
)

SELECT
    t.trajectory_id,
    t.mmsi
FROM extracted_trajectory_z13 t
JOIN extracted_crossing_z13 c ON t.cell_z21 = c.cell_z21
GROUP BY t.trajectory_id, t.mmsi
HAVING COUNT(DISTINCT c.crossing_id) = 3;


--------------------------------------------------------------------------------------------------------------
-- CoverageByMMSI
--------------------------------------------------------------------------------------------------------------
SET VARIABLE zoom = 19;
WITH cs_target_area_cells AS (
    SELECT DISTINCT CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM db_design1_v3.area_cs
    WHERE area_id  = 3
),
cs_vessel_footprint AS (
    SELECT DISTINCT mmsi, CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM db_design1_v3.trajectory_cs

    UNION ALL

    SELECT DISTINCT mmsi, CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM db_design1_v3.stop_cs
)
SELECT * FROM CS_NewCoverageByMMSI(cs_target_area_cells, cs_vessel_footprint);



