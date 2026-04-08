--------------------------------------------------------------------------------------------------------------
----------- Spatial range ---------------
--------------------------------------------------------------------------------------------------------------
WITH selected_area AS (
    SELECT area_id, geom
    FROM area_poly
    WHERE area_id = 1
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, a.area_id, 'trajectory' AS source
FROM trajectory_ls t
JOIN selected_area a ON ST_Intersects(t.geom, a.geom)
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, a.area_id, 'stop' AS source
FROM stop_poly s
JOIN selected_area a ON ST_Intersects(s.geom, a.geom);
--17 rows returned (all traj) for area_id = 1 (small_area_high_traffic)
--72 rows returned (all traj) for area_id = 2 (medium_area_high_traffic)
--123 rows returned (2 stops) for area_id = 3 (large_area_high_traffic)
-- 0 rows for all displaced(low traffic) areas

--select (st_astext(ST_Force2D(geom))) as geom from trajectory_ls where trajectory_id in (1452, 2309, 325, 1141, 1252, 1666, 1203, 2762, 550, 1922, 633, 1510, 1551, 1848, 1911, 1553, 2447)
--UNION
--select ST_astext(geom) as geom from area_poly where area_id = 1

--------------------------------------------------------------------------------------------------------------
-----------Temporal Range---------------
--------------------------------------------------------------------------------------------------------------
WITH p AS (
    -- 1 day (6.737 rows)
    SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-02 00:00:00.000' AS t_end
    -- 1 week (6.846 rows)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-08 00:00:00.000' AS t_end
    -- 1 month (6.846 rows) (same only one week data)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2026-01-01 00:00:00.000' AS t_end
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM trajectory_ls t, p
WHERE t.ts_start <= p.t_end
  AND t.ts_end >= p.t_start
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM stop_poly s, p
WHERE s.ts_start <= p.t_end
  AND s.ts_end >= p.t_start;

--------------------------------------------------------------------------------------------------------------
--Spatio-temporal Range
--------------------------------------------------------------------------------------------------------------
WITH p AS (
    --1 day: area_id 1 = (17rows), area_id 2 = (72 rows), area_id 118 = (123 rows)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-02 00:00:00.000' AS t_end
    --1 week: area_id 1 = (17rows), area_id 2 = (72 rows), area_id 118 = (123 rows)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-08 00:00:00.000' AS t_end
    --1 month: area_id 1 = (17rows), area_id 2 = (72 rows), area_id 118 = (123 rows)
    SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2026-01-01 00:00:00.000' AS t_end
), selected_areas AS (
    SELECT area_id, geom
    FROM area_poly
    WHERE area_id = 1
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, a.area_id, 'trajectory' AS source
FROM trajectory_ls t
JOIN selected_areas a ON ST_Intersects(t.geom, a.geom)
JOIN p ON t.ts_start <= p.t_end AND t.ts_end >= p.t_start
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, a.area_id, 'stop' AS source
FROM stop_poly s
JOIN selected_areas a ON ST_Intersects(s.geom, a.geom)
JOIN p ON s.ts_start <= p.t_end AND s.ts_end >= p.t_start;

--Spatio-temporal Join (“ID Temporal”)

--Via Query (Spatial Join)


