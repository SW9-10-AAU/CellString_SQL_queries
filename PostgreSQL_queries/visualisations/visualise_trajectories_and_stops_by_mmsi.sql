-- Retrieve trajectories and stops for some specific vessels (given some MMSIs)
-- Used to show trajectories and stops in the same Geo Viewer

------------ LineString/Polygon version ------------
WITH vars AS (
    -- The MMSI(s) of the vessel(s) you want to investigate --
--     SELECT ARRAY[265610950]::bigint[] AS mmsis
    SELECT ARRAY[636015105]::bigint[] AS mmsis
--     SELECT ARRAY[305978000]::bigint[] AS mmsis
),
trajectory AS (
    SELECT
        'TRAJECTORY' AS type,
        trajectory_id,
        NULL::bigint AS stop_id,
        mmsi,
        geom,
        ts_start,
        ts_end
    FROM prototype2.trajectory_ls, vars
    WHERE mmsi = ANY(vars.mmsis)
),
stop AS (
    SELECT
        'STOP' AS type,
        NULL::bigint AS trajectory_id,
        stop_id,
        mmsi,
        geom,
        ts_start,
        ts_end
    FROM prototype2.stop_poly, vars
    WHERE mmsi = ANY(vars.mmsis)
)
SELECT * FROM trajectory
UNION ALL
SELECT * FROM stop
ORDER BY ts_start;



------------ CellString version ------------
WITH vars AS (
    -- The MMSI(s) of the vessel(s) you want to investigate --
--     SELECT ARRAY[636015105]::bigint[] AS mmsis
    SELECT ARRAY[255806256]::bigint[] AS mmsis
--     SELECT ARRAY[305978000]::bigint[] AS mmsis
),
trajectory AS (
    SELECT
        'TRAJECTORY' AS type,
        trajectory_id,
        NULL::bigint AS stop_id,
        mmsi,
        CST_AsMultiPolygon(cellstring_z13, 13),
        ts_start,
        ts_end
    FROM prototype2.trajectory_supercover_cs, vars
    WHERE mmsi = ANY(vars.mmsis)
),
stop AS (
    SELECT
        'STOP' AS type,
        NULL::bigint AS trajectory_id,
        stop_id,
        mmsi,
        CST_AsMultiPolygon(cellstring_z13, 13),
        ts_start,
        ts_end
    FROM prototype2.stop_cs, vars
    WHERE mmsi = ANY(vars.mmsis)
)
SELECT * FROM trajectory
UNION ALL
SELECT * FROM stop;