LOAD spatial;
SELECT
    ls.trajectory_id,
    mmsi,
    12456789 as cell_z21,
    ts_start as ts,
    ST_AsText(ST_Force2D(geom)) AS geom
FROM jgl_etl_performance_fix.trajectory_ls as ls
WHERE ls.trajectory_id IN (1)

UNION ALL

SELECT
    ls.trajectory_id,
    mmsi,
    12456789 as cell_z21,
    ts_start as ts,
    ST_AsText(ST_Points(ST_Force2D(geom))) AS geom
FROM jgl_etl_performance_fix.trajectory_ls as ls
WHERE ls.trajectory_id IN (1)

UNION ALL

SELECT
    trajectory_id,
    mmsi,
    cell_z21,
    ts,
    ST_AsText(fast_tile_to_geom(cell_z21, 21)) AS geom
FROM jgl_etl_performance_fix.trajectory_cs
    WHERE trajectory_id IN (1);
