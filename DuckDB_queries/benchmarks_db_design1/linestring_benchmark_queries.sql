-- Linestring queries for benchmark
--------------------------------------------------------------------------------------------------------------
-- GLOBAL SCRIPT VARIABLES (Run these once before your queries)
--------------------------------------------------------------------------------------------------------------
-- [VARIABLE] Set your area_id here
SET VARIABLE area_id = 1;

-- [VARIABLE] Uncomment ONE of the intervals below for your time range:

-- 1 day
SET VARIABLE t_start = TIMESTAMP '2025-12-01 00:00:00.000';
SET VARIABLE t_end   = TIMESTAMP '2025-12-02 00:00:00.000';

-- 1 week
--SET VARIABLE t_start = TIMESTAMP '2025-12-01 00:00:00.000';
--SET VARIABLE t_end   = TIMESTAMP '2025-12-08 00:00:00.000';

-- 1 month
 --SET VARIABLE t_start = TIMESTAMP '2025-12-01 00:00:00.000';
 --SET VARIABLE t_end   = TIMESTAMP '2026-01-01 00:00:00.000';

--------------------------------------------------------------------------------------------------------------
----------- Spatial range ---------------
--------------------------------------------------------------------------------------------------------------
--area1 = 623
--area2 = 2890
--area3 = 4621
WITH selected_area AS (
    SELECT area_id, geom
    FROM p10.area_poly
    WHERE area_id = getvariable('area_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, a.area_id, 'trajectory' AS source
FROM p10.trajectory_ls t
JOIN selected_area a ON ST_Intersects(t.geom, a.geom)
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, a.area_id, 'stop' AS source
FROM p10.stop_poly s
JOIN selected_area a ON ST_Intersects(s.geom, a.geom);

--------------------------------------------------------------------------------------------------------------
-----------Temporal Range---------------
--------------------------------------------------------------------------------------------------------------
--1d = 6863
--1w = 43517 (24470traj + 19047stop)
--1m = 190.336 (104636traj + 85700stop)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM p10.trajectory_ls t
WHERE t.ts_start <= getvariable('t_end')
  AND t.ts_end >= getvariable('t_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM p10.stop_poly s
WHERE s.ts_start <= getvariable('t_end')
  AND s.ts_end >= getvariable('t_start');

--------------------------------------------------------------------------------------------------------------
---------------Spatio-temporal Range---------------
--------------------------------------------------------------------------------------------------------------
--1d/area1 = return 24 rows
--1d/area2 = return 120 rows
--1d/area3 = return 189 rows
--1w/area1 = return 123 rows
--1w/area2 = return 589 rows
--1w/area3 = return 974 rows
--1m/area1 = return 500 rows
--1m/area2 = return 2356 rows
--1m/area3 = return 3758 rows
EXPLAIN ANALYZE
WITH selected_areas AS (
    SELECT area_id, geom
    FROM p10.area_poly
    WHERE area_id = getvariable('area_id')
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, a.area_id, 'trajectory' AS source
FROM p10.trajectory_ls t
JOIN selected_areas a ON ST_Intersects(t.geom, a.geom)
WHERE t.ts_start <= getvariable('t_end') AND t.ts_end >= getvariable('t_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, a.area_id, 'stop' AS source
FROM p10.stop_poly s
JOIN selected_areas a ON ST_Intersects(s.geom, a.geom)
WHERE s.ts_start <= getvariable('t_end') AND s.ts_end >= getvariable('t_start');


-- Subquery area (does not activate R-tree index)
EXPLAIN ANALYZE
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, getvariable('area_id'), 'trajectory' AS source
FROM p10.trajectory_ls t
WHERE ST_Intersects(t.geom, (SELECT geom FROM p10.area_poly WHERE area_id = getvariable('area_id')))
AND t.ts_start <= getvariable('t_end') AND t.ts_end >= getvariable('t_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, getvariable('area_id'), 'stop' AS source
FROM p10.stop_poly s
WHERE ST_Intersects(s.geom, (SELECT geom FROM p10.area_poly WHERE area_id = getvariable('area_id')))
AND s.ts_start <= getvariable('t_end') AND s.ts_end >= getvariable('t_start');

-- Set constant area
SET VARIABLE target_geom = (SELECT geom FROM p10.area_poly WHERE area_id = getvariable('area_id'));

-- Constant area (activates R-tree index)
EXPLAIN ANALYZE
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, getvariable('area_id'), 'trajectory' AS source
FROM p10.trajectory_ls t
WHERE ST_Intersects(t.geom, getvariable('target_geom'))
AND t.ts_start <= getvariable('t_end') AND t.ts_end >= getvariable('t_start')
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, getvariable('area_id'), 'stop' AS source
FROM p10.stop_poly s
WHERE ST_Intersects(s.geom, getvariable('target_geom'))
AND s.ts_start <= getvariable('t_end') AND s.ts_end >= getvariable('t_start');


--------------------------------------------------------------------------------------------------------------
---------------Spatio-temporal Join (“ID Temporal”)---------------
--------------------------------------------------------------------------------------------------------------
SET VARIABLE target_traj_id = 2;
WITH target AS (
    SELECT trajectory_id, mmsi, ts_start, ts_end, geom
    FROM p10.trajectory_ls
    WHERE trajectory_id = getvariable('target_traj_id')
)
SELECT DISTINCT c.mmsi, c.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM target t
JOIN p10.trajectory_ls c
  ON ST_Intersects(c.geom, t.geom)
 AND c.mmsi <> t.mmsi
 AND c.ts_start <= t.ts_end
 AND c.ts_end >= t.ts_start
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM target t
JOIN p10.stop_poly s
  ON ST_Intersects(s.geom, t.geom)
 AND s.mmsi <> t.mmsi
 AND s.ts_start <= t.ts_end
 AND s.ts_end >= t.ts_start;
--------------------------------------------------------------------------------------------------------------
--Via Query (Spatial Join)
--------------------------------------------------------------------------------------------------------------

--Skagen-Storebælt-Bornholm
SELECT
    traj.trajectory_id,
    traj.mmsi,
FROM p10.trajectory_ls AS traj,
     p10.crossing_ls AS crossingA,
     p10.crossing_ls AS crossingB,
     p10.crossing_ls AS crossingC
WHERE crossingA.name = 'Skagen'
  AND crossingB.name = 'Storebælt'
  AND crossingC.name = 'Bornholm'
  AND ST_Intersects(traj.geom, crossingA.geom)
  AND ST_Intersects(traj.geom, crossingB.geom)
  AND ST_Intersects(traj.geom, crossingC.geom);


--Skagen-Kattegat-Storebælt
SELECT
    traj.trajectory_id,
    traj.mmsi,
FROM p10.trajectory_ls AS traj,
     p10.crossing_ls AS crossingA,
     p10.crossing_ls AS crossingB,
     p10.crossing_ls AS crossingC
WHERE crossingA.name = 'Skagen'
  AND crossingB.name = 'Kattegat'
  AND crossingC.name = 'Storebælt'
  AND ST_Intersects(traj.geom, crossingA.geom)
  AND ST_Intersects(traj.geom, crossingB.geom)
  AND ST_Intersects(traj.geom, crossingC.geom);



