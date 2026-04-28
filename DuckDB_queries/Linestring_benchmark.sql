-- Linestring queries for benchmark

load spatial;

SET VARIABLE region_id = 3;
SET VARIABLE query_region = (SELECT geom FROM p10_ls.region_poly WHERE region_id = getvariable('region_id'));

SET VARIABLE query_traj_id = 2;

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
----------- Spatial Range ---------------
--------------------------------------------------------------------------------------------------------------
WITH query_region AS (
    SELECT region_id, geom
    FROM p10_ls.region_poly
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
JOIN query_region q ON ST_Intersects(t.geom, q.geom)

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_ls.stop_poly s
JOIN query_region q ON ST_Intersects(s.geom, q.geom);

-- Constant region (activates R-tree index)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE ST_Intersects(t.geom, getvariable('query_region'))

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_ls.stop_poly s
WHERE ST_Intersects(s.geom, getvariable('query_region'));

--------------------------------------------------------------------------------------------------------------
----------- Temporal Range ---------------
--------------------------------------------------------------------------------------------------------------
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
--------------- Spatio-temporal Range ---------------
--------------------------------------------------------------------------------------------------------------
WITH query_region AS (
    SELECT region_id, geom
    FROM p10_ls.region_poly
    WHERE region_id = getvariable('region_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
JOIN query_region q ON ST_Intersects(t.geom, q.geom)
WHERE t.ts_start <= getvariable('ts_period_end') AND t.ts_end >= getvariable('ts_period_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_ls.stop_poly s
JOIN query_region q ON ST_Intersects(s.geom, q.geom)
WHERE s.ts_start <= getvariable('ts_period_end') AND s.ts_end >= getvariable('ts_period_start');


-- Subquery region (does not activate R-tree index)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE ST_Intersects(t.geom, (SELECT geom FROM p10_ls.region_poly WHERE region_id = getvariable('region_id')))
AND t.ts_start <= getvariable('ts_period_end') AND t.ts_end >= getvariable('ts_period_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_ls.stop_poly s
WHERE ST_Intersects(s.geom, (SELECT geom FROM p10_ls.region_poly WHERE region_id = getvariable('region_id')))
AND s.ts_start <= getvariable('ts_period_end') AND s.ts_end >= getvariable('ts_period_start');

-- Constant region (activates R-tree index)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE ST_Intersects(t.geom, getvariable('query_region'))
AND t.ts_start <= getvariable('ts_period_end') AND t.ts_end >= getvariable('ts_period_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_ls.stop_poly s
WHERE ST_Intersects(s.geom, getvariable('query_region'))
AND s.ts_start <= getvariable('ts_period_end') AND s.ts_end >= getvariable('ts_period_start');


--------------------------------------------------------------------------------------------------------------
--------------- ID Temporal ---------------
--------------------------------------------------------------------------------------------------------------
WITH query_traj AS (
    SELECT trajectory_id, mmsi, ts_start, ts_end, geom
    FROM p10_ls.trajectory_ls
    WHERE trajectory_id = getvariable('query_traj_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM query_traj q
JOIN p10_ls.trajectory_ls t ON ST_Intersects(t.geom, q.geom)
 AND t.mmsi <> q.mmsi
 AND t.ts_start <= q.ts_end
 AND t.ts_end >= q.ts_start

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM query_traj q
JOIN p10_ls.stop_poly s ON ST_Intersects(s.geom, q.geom)
 AND s.mmsi <> q.mmsi
 AND s.ts_start <= q.ts_end
 AND s.ts_end >= q.ts_start;


-- Constant query trajectory (activates R-tree index)
SET VARIABLE query_traj_mmsi = (SELECT mmsi FROM p10_ls.trajectory_ls WHERE trajectory_id = getvariable('query_traj_id'));
SET VARIABLE query_traj_geom = (SELECT geom FROM p10_ls.trajectory_ls WHERE trajectory_id = getvariable('query_traj_id'));
SET VARIABLE query_traj_ts_start = (SELECT ts_start FROM p10_ls.trajectory_ls WHERE trajectory_id = getvariable('query_traj_id'));
SET VARIABLE query_traj_ts_end = (SELECT ts_end FROM p10_ls.trajectory_ls WHERE trajectory_id = getvariable('query_traj_id'));

SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10_ls.trajectory_ls t
WHERE ST_Intersects(t.geom, getvariable('query_traj_geom'))
 AND t.mmsi <> getvariable('query_traj_mmsi')
 AND t.ts_start <= getvariable('query_traj_ts_end')
 AND t.ts_end >= getvariable('query_traj_ts_start')

UNION ALL

SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10_ls.stop_poly s
WHERE ST_Intersects(s.geom, getvariable('query_traj_geom'))
 AND s.mmsi <> getvariable('query_traj_mmsi')
 AND s.ts_start <= getvariable('query_traj_ts_end')
 AND s.ts_end >= getvariable('query_traj_ts_start');


--------------------------------------------------------------------------------------------------------------
--------------- Via Query ---------------
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