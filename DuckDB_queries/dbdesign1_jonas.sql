INSTALL spatial;
LOAD spatial;

SELECT trajectory_id FROM db_design1_missing_trajs.trajectory_ls
EXCEPT
SELECT trajectory_id FROM db_design1_missing_trajs.trajectory_cs
ORDER BY trajectory_id;

SELECT
    ls.mmsi,
    ls.trajectory_id,
    round(ST_Length_Spheroid(ls.geom),2) as traj_length,
    ST_AsText(ST_Force2D(ls.geom)) as geom
FROM
    db_design1_missing_trajs.trajectory_ls ls
LEFT JOIN
    db_design1_missing_trajs.trajectory_cs cs ON ls.trajectory_id = cs.trajectory_id
WHERE
    cs.trajectory_id IS NULL
ORDER BY traj_length;

-- MISSING TRAJS
SELECT mmsi, trajectory_id, ST_AsText(ST_Force2D(geom)) as ls_geom FROM db_design1_missing_trajs.trajectory_ls
WHERE trajectory_id IN (
    86,
    483,
    484,
    485,
    487,
    488,
    490,
    491,
    493,
    494,
    497,
    498,
    499,
    500,
    501,
    502,
    503,
    504,
    507,
    508,
    510,
    2113,
    2114,
    2998,
    3266);

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


LOAD spatial;

SELECT crossing_id, name, ST_AsText(geom)
FROM jgl_area_crossing_test.crossing_ls
WHERE crossing_id = 1

UNION ALL

SELECT crossing_id, name, ST_AsText(fast_tile_to_geom(cell_z21, 21)) AS geom
FROM jgl_area_crossing_test.crossing_cs
WHERE crossing_id = 1;



SELECT area_id, name,ST_AsText(geom)
FROM jgl_etl_performance_fix.area_poly
WHERE area_id = 1

UNION ALL

SELECT area_id, name, ST_AsText(fast_tile_to_geom(cell_z21, 21)) AS geom
FROM jgl_etl_performance_fix.area_cs
WHERE area_id = 1;