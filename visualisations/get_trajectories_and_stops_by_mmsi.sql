-- Retrieve trajectories and stops for some specific vessels (given some MMSIs)
-- Used to show trajectories and stops in the same Geo Viewer

------------ LineString/Polygon version ------------
WITH vars AS (
    -- The MMSI(s) of the vessel(s) you want to investigate --
    SELECT ARRAY[210051000, 636015105]::bigint[] AS mmsis
),
trajectory AS (
    SELECT
        'trajectory' AS type,
        trajectory_id,
        NULL::bigint AS stop_id,
        mmsi,
        geom,
        ts_start,
        ts_end
    FROM prototype1.trajectory_ls, vars
    WHERE mmsi = ANY(vars.mmsis)
),
stop AS (
    SELECT
        'stop' AS type,
        NULL::bigint AS trajectory_id,
        stop_id,
        mmsi,
        geom,
        ts_start,
        ts_end
    FROM prototype1.stop_poly, vars
    WHERE mmsi = ANY(vars.mmsis)
)
SELECT * FROM trajectory
UNION ALL
SELECT * FROM stop;



------------ CellString version ------------
WITH vars AS (
    -- The MMSI(s) of the vessel(s) you want to investigate --
    SELECT ARRAY[210051000, 636015105]::bigint[] AS mmsis
),
trajectory AS (
    SELECT
        'trajectory' AS type,
        trajectory_id,
        NULL::bigint AS stop_id,
        mmsi,
        cellstring,
        ts_start,
        ts_end
    FROM prototype1.trajectory_cs, vars
    WHERE mmsi = ANY(vars.mmsis)
),
stop AS (
    SELECT
        'stop' AS type,
        NULL::bigint AS trajectory_id,
        stop_id,
        mmsi,
        cellstring,
        ts_start,
        ts_end
    FROM prototype1.stop_cs, vars
    WHERE mmsi = ANY(vars.mmsis)
)
SELECT * FROM trajectory
UNION ALL
SELECT * FROM stop;