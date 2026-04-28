-- Cellstring queries for benchmark

SET VARIABLE region_id = 3;

SET VARIABLE query_traj_id = 2;

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
--------------- Spatial Range ---------------
--------------------------------------------------------------------------------------------------------------
WITH query_region AS (
    SELECT region_id, cell_z21
    FROM p10_cs.region_cs
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_cs.trajectory_cs t
JOIN query_region q ON t.cell_z21 = q.cell_z21

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_cs.stop_cs s
JOIN query_region q ON s.cell_z21 = q.cell_z21;


--------------------------------------------------------------------------------------------------------------
--------------- Temporal Range ---------------
--------------------------------------------------------------------------------------------------------------
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
--------------- Spatio-temporal Range ---------------
--------------------------------------------------------------------------------------------------------------
WITH query_region AS (
    SELECT region_id, cell_z21
    FROM p10_cs.region_cs
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_cs.trajectory_cs t
JOIN query_region q ON t.cell_z21 = q.cell_z21
WHERE t.ts <= getvariable('ts_period_end')
  AND t.ts + (INTERVAL (t.delta_sec) SECOND) >= getvariable('ts_period_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_cs.stop_cs s
JOIN query_region q ON s.cell_z21 = q.cell_z21
WHERE s.ts_start <= getvariable('ts_period_end')
  AND s.ts_end >= getvariable('ts_period_start');

--------------------------------------------------------------------------------------------------------------
--------------- ID Temporal ---------------
--------------------------------------------------------------------------------------------------------------
WITH query_traj AS (
    SELECT mmsi, trajectory_id, ts, delta_sec, cell_z21
    FROM p10_cs.trajectory_cs
    WHERE trajectory_id = getvariable('query_traj_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_cs.trajectory_cs t
JOIN query_traj q ON t.cell_z21 = q.cell_z21
WHERE t.mmsi <> q.mmsi
  AND t.ts <= q.ts + (INTERVAL (q.delta_sec) SECOND)
  AND t.ts + (INTERVAL (t.delta_sec) SECOND) >= q.ts

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_cs.stop_cs AS s
JOIN query_traj q ON s.cell_z21 = q.cell_z21
WHERE s.mmsi <> q.mmsi
  AND s.ts_start <= q.ts + (INTERVAL (q.delta_sec) SECOND)
  AND s.ts_end >= q.ts;

--------------------------------------------------------------------------------------------------------------
--------------- Via Query ---------------
--------------------------------------------------------------------------------------------------------------

--The Sound
SELECT
    t.trajectory_id,
    t.mmsi
FROM p10_cs.trajectory_cs t
JOIN p10_cs.passage_cs p ON t.cell_z21 = p.cell_z21
WHERE p.name IN ('Skagen', 'Sundet Syd', 'Bornholms Gate')
GROUP BY t.trajectory_id, t.mmsi
HAVING COUNT(DISTINCT p.passage_id) = 3;

--The Great Belt
SELECT
    t.trajectory_id,
    t.mmsi
FROM p10_cs.trajectory_cs t
JOIN p10_cs.passage_cs p ON t.cell_z21 = p.cell_z21
WHERE p.name IN ('Skagen', 'Storebælt Syd', 'Bornholms Gate')
GROUP BY t.trajectory_id, t.mmsi
HAVING COUNT(DISTINCT p.passage_id) = 3;

--The Kieler Canal
SELECT
    t.trajectory_id,
    t.mmsi
FROM p10_cs.trajectory_cs t
JOIN p10_cs.passage_cs p ON t.cell_z21 = p.cell_z21
WHERE p.name IN ('Kiel', 'Kadetrenden', 'Bornholms Gate')
GROUP BY t.trajectory_id, t.mmsi
HAVING COUNT(DISTINCT p.passage_id) = 3;


--------------------------------------------------------------------------------------------------------------
--------------- CoverageByMMSI ---------------
--------------------------------------------------------------------------------------------------------------
SET VARIABLE coverage_region_id = 7;
SET VARIABLE zoom = 19;

WITH query_region AS (
    SELECT DISTINCT CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM p10_cs.region_cs
    WHERE region_id = getvariable('coverage_region_id')
),
cs_vessel_footprint AS (
    SELECT DISTINCT mmsi, CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM p10_cs.trajectory_cs

    UNION ALL

    SELECT DISTINCT mmsi, CS_GetParentCellId(cell_z21, 21, getvariable('zoom')) AS cell_z21
    FROM p10_cs.stop_cs
)
SELECT * FROM CS_CoverageByMMSI(query_region, cs_vessel_footprint);

-- z21 version
WITH query_region AS (
    SELECT DISTINCT cell_z21
    FROM p10_cs.region_cs
    WHERE region_id = getvariable('coverage_region_id')
),
cs_vessel_footprint AS (
    SELECT DISTINCT mmsi, cell_z21
    FROM p10_cs.trajectory_cs

    UNION ALL

    SELECT DISTINCT mmsi, cell_z21
    FROM p10_cs.stop_cs
)
SELECT * FROM CS_CoverageByMMSI(query_region, cs_vessel_footprint);
