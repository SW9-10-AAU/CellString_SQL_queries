-- Cellstring queries for benchmark

--------------------------------------------------------------------------------------------------------------
-- GLOBAL SCRIPT VARIABLES (Run these once before your queries)
--------------------------------------------------------------------------------------------------------------
-- [VARIABLE] Set your region_id here
SET VARIABLE region_id = 3;

-- [VARIABLE] Uncomment ONE of the intervals below for your time range:
-- 1_day
-- SET VARIABLE ts_period_start = TIMESTAMP '2025-12-01 00:00:00.000';
-- SET VARIABLE ts_period_end   = TIMESTAMP '2025-12-02 00:00:00.000';

-- 1_week
--SET VARIABLE ts_period_start = TIMESTAMP '2025-12-01 00:00:00.000';
--SET VARIABLE ts_period_end   = TIMESTAMP '2025-12-08 00:00:00.000';

-- 1_month
SET VARIABLE ts_period_start = TIMESTAMP '2025-12-01 00:00:00.000';
SET VARIABLE ts_period_end   = TIMESTAMP '2026-01-01 00:00:00.000';


--------------------------------------------------------------------------------------------------------------
-- 1. Spatial Range
--------------------------------------------------------------------------------------------------------------
-- region 1 = 630 rows
-- region 2 = 2892 rows
-- region 3 = 4622 rows
WITH query_region AS (
    SELECT region_id, cell_z21
    FROM p10_cs.region_cs
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, r.region_id, 'trajectory' AS source
FROM p10_cs.trajectory_cs t
JOIN query_region r ON t.cell_z21 = r.cell_z21

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, r.region_id, 'stop' AS source
FROM p10_cs.stop_cs s
JOIN query_region r ON s.cell_z21 = r.cell_z21;


--------------------------------------------------------------------------------------------------------------
-- 2. Temporal Range
--------------------------------------------------------------------------------------------------------------
--1d = 6863
--1w = 43515 (24468traj + 19047stop)
--1m = 190.313 (104613traj + 85700stop)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_cs.trajectory_cs t
WHERE t.ts <= getvariable('ts_period_end')
  AND t.ts + (INTERVAL (t.delta_sec) SECOND) >= getvariable('ts_period_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_cs.stop_cs s
WHERE s.ts_start <= getvariable('ts_period_end')
  AND s.ts_end >= getvariable('ts_period_start');

--------------------------------------------------------------------------------------------------------------
-- 3. Spatio-temporal Range
--------------------------------------------------------------------------------------------------------------
--1d/region1 = return 17 rows
--1d/region2 = return 72 rows
--1d/region3 = return 122 rows
--1w/region1 = return 107 rows
--1w/region2 = return 533 rows
--1w/region3 = return 901 rows
--1m/region1 = return 494 rows
--1m/region2 = return 2298 rows
--1m/region3 = return 3655 rows
WITH query_region AS (
    SELECT region_id, cell_z21
    FROM p10_cs.region_cs
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, r.region_id, 'trajectory' AS source
FROM p10_cs.trajectory_cs t
JOIN query_region r ON t.cell_z21 = r.cell_z21
WHERE t.ts <= getvariable('ts_period_end')
  AND t.ts + (INTERVAL (t.delta_sec) SECOND) >= getvariable('ts_period_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, r.region_id, 'stop' AS source
FROM p10_cs.stop_cs s
JOIN query_region r ON s.cell_z21 = r.cell_z21
WHERE s.ts_start <= getvariable('ts_period_end')
  AND s.ts_end >= getvariable('ts_period_start');

--------------------------------------------------------------------------------------------------------------
--Spatio-temporal Join (“ID Temporal”)
--------------------------------------------------------------------------------------------------------------
SET VARIABLE query_traj_id = 101972;
WITH query_traj AS (
    SELECT mmsi, trajectory_id, ts, delta_sec, cell_z21
    FROM p10_cs.trajectory_cs
    WHERE trajectory_id = getvariable('query_traj_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_cs.trajectory_cs AS t
JOIN query_traj AS q ON t.cell_z21 = q.cell_z21
WHERE q.ts <= t.ts + (INTERVAL (t.delta_sec) SECOND)
  AND q.ts + (INTERVAL (q.delta_sec) SECOND) >= t.ts;
  AND t.mmsi <> q.mmsi;

UNION ALL

SELECT DISTINCT t.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_cs.stop_cs AS s
JOIN query_traj AS q ON t.cell_z21 = q.cell_z21
WHERE q.ts <= s.ts_end
  AND q.ts + (INTERVAL (q.delta_sec) SECOND) >= s.ts_start;
  AND s.mmsi <> q.mmsi;

--------------------------------------------------------------------------------------------------------------
--Via Query (Spatial Join)
--------------------------------------------------------------------------------------------------------------
--The Sound
SELECT
    t.trajectory_id,
    t.mmsi
FROM p10_cs.trajectory_cs t
JOIN p10_cs.passage_cs p ON t.cell_z21 = p.cell_z21
WHERE p.name IN ('Skagen', 'Sundet Syd', 'Bornholms Gate')
GROUP BY t.trajectory_id, t.mmsi
-- Hit all 3 unique passages
HAVING COUNT(DISTINCT p.passage_id) = 3;

--The Great Belt
SELECT
    t.trajectory_id,
    t.mmsi
FROM p10_cs.trajectory_cs t
JOIN p10_cs.passage_cs p ON t.cell_z21 = p.cell_z21
WHERE p.name IN ('Skagen', 'Storebælt Syd', 'Bornholms Gate')
GROUP BY t.trajectory_id, t.mmsi
-- Hit all 3 unique passages
HAVING COUNT(DISTINCT p.passage_id) = 3;

--The Kieler Canal
SELECT
    t.trajectory_id,
    t.mmsi
FROM p10_cs.trajectory_cs t
JOIN p10_cs.passage_cs p ON t.cell_z21 = p.cell_z21
WHERE p.name IN ('Kiel', 'Kadetrenden', 'Bornholms Gate')
GROUP BY t.trajectory_id, t.mmsi
-- Hit all 3 unique passages
HAVING COUNT(DISTINCT p.passage_id) = 3;


--------------------------------------------------------------------------------------------------------------
-- CoverageByMMSI
--------------------------------------------------------------------------------------------------------------
SET VARIABLE zoom = 19;
-- EXPLAIN ANALYZE
WITH cs_target_region_cells AS (
    SELECT DISTINCT CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM p10_cs.region_cs
    WHERE region_id  = 10
),
cs_vessel_footprint AS (
    SELECT DISTINCT mmsi, CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM p10_cs.trajectory_cs

    UNION ALL

    SELECT DISTINCT mmsi, CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM p10_cs.stop_cs
)
SELECT * FROM CS_NewCoverageByMMSI(cs_target_region_cells, cs_vessel_footprint);

--z21
EXPLAIN ANALYZE
WITH cs_target_region_cells AS (
    SELECT DISTINCT cell_z21
    FROM p10_cs.region_cs
    WHERE region_id  = 10
),
cs_vessel_footprint AS (
    SELECT DISTINCT mmsi, cell_z21
    FROM p10_cs.trajectory_cs

    UNION ALL

    SELECT DISTINCT mmsi, cell_z21
    FROM p10_cs.stop_cs
)
SELECT * FROM CS_NewCoverageByMMSI(cs_target_region_cells, cs_vessel_footprint);
