-- MMSI trajectory and stops (convex + concave)
SELECT
    'trajectory' AS type,
    geom AS geom,
    trajectory_id AS id,
    mmsi AS mmsi,
    ts_start AS ts_start,
    ts_end AS ts_end,
    NULL::text AS stop_type
FROM prototype2.trajectory_ls
WHERE mmsi = 538007980

UNION ALL

SELECT
    'stop' AS type,
    geom AS geom,
    stop_id AS id,
    mmsi AS mmsi,
    ts_start AS ts_start,
    ts_end AS ts_end,
    'convex' AS stop_type
FROM prototype2.stop_poly
WHERE mmsi = 538007980

UNION ALL

SELECT
    'concave_stop' AS type,
    geom AS geom,
    stop_id AS id,
    mmsi AS mmsi,
    ts_start AS ts_start,
    ts_end AS ts_end,
    'concave' AS stop_type
FROM prototype2.concave_stop_poly
WHERE mmsi = 538007980;



--Show cellstring difference for zoom lvl on concave vs convex
SELECT
    ls.stop_id,
    ls.mmsi,
   -- ls.geom AS stop_geom,
    --CST_AsMultiPolygon(cs.cellstring_z13, 13) AS cells_z13,
   -- CST_AsMultiPolygon(cs.cellstring_z17, 17) AS cells_z17,
    CST_AsMultiPolygon(cs.cellstring_z21, 21) AS cells_z21
FROM prototype2.stop_poly ls
JOIN prototype2.stop_cs cs
    ON ls.stop_id = cs.stop_id
WHERE ls.stop_id = 3999

UNION

SELECT
    ls.stop_id,
    ls.mmsi,
    --ls.geom AS stop_geom,
    --CST_AsMultiPolygon(cs.cellstring_z13, 13) AS cells_z13,
    --CST_AsMultiPolygon(cs.cellstring_z17, 17) AS cells_z17,
    CST_AsMultiPolygon(cs.cellstring_z21, 21) AS cells_z21
FROM prototype2.concave_stop_poly ls
JOIN prototype2.concave_stop_cs cs
    ON ls.stop_id = cs.stop_id
WHERE ls.stop_id = 3942;
