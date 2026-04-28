-- Linestring queries for benchmark
--------------------------------------------------------------------------------------------------------------
-- GLOBAL SCRIPT VARIABLES (Run these once before your queries)
--------------------------------------------------------------------------------------------------------------
load spatial;

-- [VARIABLE] Set your region_id here
SET VARIABLE region_id = 3;
SET VARIABLE query_region = (SELECT geom FROM p10_ls.region_poly WHERE region_id = getvariable('region_id'));

-- [VARIABLE] Uncomment ONE of the intervals below for your time range:

-- 1 day
-- SET VARIABLE ts_period_start = TIMESTAMP '2025-12-01 00:00:00.000';
-- SET VARIABLE ts_period_end   = TIMESTAMP '2025-12-02 00:00:00.000';

-- 1 week
--SET VARIABLE ts_period_start = TIMESTAMP '2025-12-01 00:00:00.000';
--SET VARIABLE ts_period_end   = TIMESTAMP '2025-12-08 00:00:00.000';

-- 1 month
SET VARIABLE ts_period_start = TIMESTAMP '2025-12-01 00:00:00.000';
SET VARIABLE ts_period_end   = TIMESTAMP '2026-01-01 00:00:00.000';

--------------------------------------------------------------------------------------------------------------
----------- Spatial range ---------------
--------------------------------------------------------------------------------------------------------------
--region1 = 623
--region2 = 2890
--region3 = 4621
WITH selected_region AS (
    SELECT region_id, geom
    FROM p10_ls.region_poly
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, r.region_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
JOIN selected_region r ON ST_Intersects(t.geom, r.geom)
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, r.region_id, 'stop' AS source
FROM p10_ls.stop_poly s
JOIN selected_region r ON ST_Intersects(s.geom, r.geom);

-- Constant region (activates R-tree index)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, r.region_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE ST_Intersects(t.geom, getvariable('query_region'))
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, r.region_id, 'stop' AS source
FROM p10_ls.stop_poly s
WHERE ST_Intersects(s.geom, getvariable('query_region'))

--------------------------------------------------------------------------------------------------------------
-----------Temporal Range---------------
--------------------------------------------------------------------------------------------------------------
--1d = 6863
--1w = 43517 (24470traj + 19047stop)
--1m = 190.336 (104636traj + 85700stop)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE t.ts_start <= getvariable('ts_period_end')
  AND t.ts_end >= getvariable('ts_period_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_ls.stop_poly s
WHERE s.ts_start <= getvariable('ts_period_end')
  AND s.ts_end >= getvariable('ts_period_start');

--------------------------------------------------------------------------------------------------------------
---------------Spatio-temporal Range---------------
--------------------------------------------------------------------------------------------------------------
--1d/region1 = return 24 rows
--1d/region2 = return 120 rows
--1d/region3 = return 189 rows
--1w/region1 = return 123 rows
--1w/region2 = return 589 rows
--1w/region3 = return 974 rows
--1m/region1 = return 500 rows
--1m/region2 = return 2356 rows
--1m/region3 = return 3758 rows
WITH selected_region AS (
    SELECT region_id, geom
    FROM p10_ls.region_poly
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, r.region_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
JOIN selected_region r ON ST_Intersects(t.geom, r.geom)
WHERE t.ts_start <= getvariable('ts_period_end') AND t.ts_end >= getvariable('ts_period_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, r.region_id, 'stop' AS source
FROM p10_ls.stop_poly s
JOIN selected_region r ON ST_Intersects(s.geom, r.geom)
WHERE s.ts_start <= getvariable('ts_period_end') AND s.ts_end >= getvariable('ts_period_start');


-- Subquery region (does not activate R-tree index)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, getvariable('region_id'), 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE ST_Intersects(t.geom, (SELECT geom FROM p10_ls.region_poly WHERE region_id = getvariable('region_id')))
AND t.ts_start <= getvariable('ts_period_end') AND t.ts_end >= getvariable('ts_period_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, getvariable('region_id'), 'stop' AS source
FROM p10_ls.stop_poly s
WHERE ST_Intersects(s.geom, (SELECT geom FROM p10_ls.region_poly WHERE region_id = getvariable('region_id')))
AND s.ts_start <= getvariable('ts_period_end') AND s.ts_end >= getvariable('ts_period_start');

-- Constant region (activates R-tree index)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, getvariable('region_id'), 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE ST_Intersects(t.geom, getvariable('query_region'))
AND t.ts_start <= getvariable('ts_period_end') AND t.ts_end >= getvariable('ts_period_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, getvariable('region_id'), 'stop' AS source
FROM p10_ls.stop_poly s
WHERE ST_Intersects(s.geom, getvariable('query_region'))
AND s.ts_start <= getvariable('ts_period_end') AND s.ts_end >= getvariable('ts_period_start');


--------------------------------------------------------------------------------------------------------------
---------------Spatio-temporal Join (“ID Temporal”)---------------
--------------------------------------------------------------------------------------------------------------
SET VARIABLE query_traj_id = 2;
WITH query_traj AS (
    SELECT trajectory_id, mmsi, ts_start, ts_end, geom
    FROM p10_ls.trajectory_ls
    WHERE trajectory_id = getvariable('query_traj_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM query_traj q
JOIN p10_ls.trajectory_ls t
  ON ST_Intersects(c.geom, t.geom)
 AND t.mmsi <> t.mmsi
 AND t.ts_start <= t.ts_end
 AND t.ts_end >= t.ts_start

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM query_traj q
JOIN p10_ls.stop_poly s
  ON ST_Intersects(s.geom, t.geom)
 AND s.mmsi <> t.mmsi
 AND s.ts_start <= t.ts_end
 AND s.ts_end >= t.ts_start;


--------------------------------------------------------------------------------------------------------------
--Via Query (Spatial Join)
--------------------------------------------------------------------------------------------------------------

-- The Sound
SELECT DISTINCT
    traj.trajectory_id,
    traj.mmsi,
FROM p10_ls.trajectory_ls AS traj,
     p10_ls.passage_ls AS passageA,
     p10_ls.passage_ls AS passageB,
     p10_ls.passage_ls AS passageC
WHERE passageA.name = 'Skagen'
  AND passageB.name = 'Sundet Syd'
  AND passageC.name = 'Bornholms Gate'
  AND ST_Intersects(traj.geom, passageA.geom)
  AND ST_Intersects(traj.geom, passageB.geom)
  AND ST_Intersects(traj.geom, passageC.geom);


--The Great Belt
SELECT DISTINCT
    traj.trajectory_id,
    traj.mmsi,
FROM p10_ls.trajectory_ls AS traj,
     p10_ls.passage_ls AS passageA,
     p10_ls.passage_ls AS passageB,
     p10_ls.passage_ls AS passageC
WHERE passageA.name = 'Skagen'
  AND passageB.name = 'Storebælt Syd'
  AND passageC.name = 'Bornholms Gate'
  AND ST_Intersects(traj.geom, passageA.geom)
  AND ST_Intersects(traj.geom, passageB.geom)
  AND ST_Intersects(traj.geom, passageC.geom);


--The Kieler Canal
SELECT DISTINCT
    traj.trajectory_id,
    traj.mmsi,
FROM p10_ls.trajectory_ls AS traj,
     p10_ls.passage_ls AS passageA,
     p10_ls.passage_ls AS passageB,
     p10_ls.passage_ls AS passageC
WHERE passageA.name = 'Kiel'
  AND passageB.name = 'Kadetrenden'
  AND passageC.name = 'Bornholms Gate'
  AND ST_Intersects(traj.geom, passageA.geom)
  AND ST_Intersects(traj.geom, passageB.geom)
  AND ST_Intersects(traj.geom, passageC.geom);