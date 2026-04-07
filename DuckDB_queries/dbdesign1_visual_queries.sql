install spatial;
load spatial;

-- Cell counts
Select trajectory_id, count(*) as cell_count from db_design1_queriestest.trajectory_cs
GROUP by trajectory_id;

-- show the trajectory as a polygon
SELECT ST_AsText(fast_CST_AsPolygon('db_design1_queriestest.trajectory_cs', 'trajectory_id', 1)) AS trajectory_poly;

-- show the trajectory as cells
SELECT
    ST_AsText(fast_tile_to_geom(unique_cell, 21)) AS trajectory_polygon
FROM (
    SELECT  DISTINCT cell_z21 as unique_cell
    FROM db_design1.trajectory_cs
    WHERE trajectory_id = 1
    order by ts
);

--Visualize Intersection with time (trajectories)
WITH target_cells AS (
    SELECT cell_z21, ts, mmsi
    FROM db_design1_queriestest.trajectory_cs
    WHERE trajectory_id = 33
)
SELECT DISTINCT t.trajectory_id,
                tc.mmsi AS this_ship,
                t.mmsi AS other_ship,
                t.cell_z21 as in_cell,
                EXTRACT(EPOCH FROM (t.ts - tc.ts)) AS time_diff_seconds,
                ST_AsText(fast_tile_to_geom(t.cell_z21, 21)) AS intersecting_cell_polygon
FROM db_design1_queriestest.trajectory_cs t
JOIN target_cells tc
  ON t.cell_z21 = tc.cell_z21
WHERE t.trajectory_id <> 33
AND t.ts BETWEEN tc.ts - INTERVAL '300000 seconds'
AND tc.ts + INTERVAL '300000 seconds'

UNION ALL

SELECT trajectory_id, mmsi, '', '', '',  ST_AsText(ST_force2d(geom)) FROM db_design1_queriestest.trajectory_ls ls
WHERE ls.trajectory_id IN (33, 1251, 1252);


--Visualize Intersection with time (trajectories)
WITH target_cells AS (
    SELECT cell_z21, ts, mmsi
    FROM db_design1_queriestest.trajectory_cs
    WHERE trajectory_id = 1
)
SELECT DISTINCT t.trajectory_id,
                tc.mmsi AS this_ship,
                t.mmsi AS other_ship,
                t.cell_z21 as in_cell,
                EXTRACT(EPOCH FROM (t.ts - tc.ts)) AS time_diff_seconds,
                ST_AsText(fast_tile_to_geom(t.cell_z21, 21)) AS intersecting_cell_polygon
FROM db_design1_queriestest.trajectory_cs t
JOIN target_cells tc
  ON t.cell_z21 = tc.cell_z21
WHERE t.trajectory_id <> 1
AND t.ts BETWEEN tc.ts - INTERVAL '10 seconds'
AND tc.ts + INTERVAL '10 seconds'

UNION ALL

SELECT trajectory_id, mmsi, '', '', '',  ST_AsText(ST_force2d(geom)) FROM db_design1_queriestest.trajectory_ls ls
WHERE ls.trajectory_id IN (1, 2299);

SELECT DISTINCT trajectory_id, 'Difference', ST_asText(fast_tile_to_geom(cell_z21,21)) as Difference
FROM db_design1_queriestest.trajectory_cs
WHERE trajectory_id = 1252  -- replace with the trajectory ID for A
  AND cell_z21 NOT IN (
      SELECT cell_z21
      FROM db_design1_queriestest.trajectory_cs
      WHERE trajectory_id = 33  -- replace with trajectory ID for B
  )

UNION ALL

select trajectory_id, 'non overlap', ST_asText(fast_tile_to_geom(cell_z21,21)) from db_design1_queriestest.trajectory_cs where trajectory_id in (33, 1252);

-- Test of CST_AsPolygon

CREATE OR REPLACE MACRO fast_CST_AsPolygon(tbl_name, id_col, target_id) AS (
    SELECT                                                     --55.52522979763203 point in duckdb (used)
                                                               --14.547958129000252 lon from difference (ONE MORE)
        ST_Union_Agg(ST_buffer((fast_tile_to_geom(cell_val, 21)), 0.00000000000001))
    FROM query(
        'SELECT DISTINCT cell_z21 AS cell_val FROM ' || tbl_name ||
        ' WHERE ' || id_col || ' = ' || target_id
    )
);


SELECT trajectory_id, ST_AsText(
    fast_CST_AsPolygon('db_design1_queriestest.trajectory_cs', 'trajectory_id', 12)
) AS polygon_geom,
ST_AsText(ST_Force2D(geom)) AS linestring_geom,
ST_AsText(
    ST_Difference(
        ST_Force2D(geom),  -- your LINESTRING
        fast_CST_AsPolygon('db_design1_queriestest.trajectory_cs', 'trajectory_id', 12)  -- the polygon
    )
) AS diff_geom,
FROM db_design1_queriestest.trajectory_ls
WHERE trajectory_id = 12;

