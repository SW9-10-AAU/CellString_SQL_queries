WITH
-- ============================================================
-- TRAJECTORY LINESTRING
-- ============================================================
traj_ls AS (
    SELECT
        COUNT(*) AS rec,
        COALESCE(SUM(ST_NPoints(geom)), 0) AS pts
    FROM prototype2.trajectory_ls
),

traj_ls_repeat AS (
    -- same LS points shown for z13, z17, z21
    SELECT pts, rec FROM traj_ls
),

-- ============================================================
-- TRAJECTORY CS (Bresenham version)
-- ============================================================
traj_b AS (
    SELECT
        COUNT(*) AS rec,
        COALESCE(SUM(cardinality(cellstring_z13)), 0) AS z13,
        COALESCE(SUM(cardinality(cellstring_z17)), 0) AS z17,
        COALESCE(SUM(cardinality(cellstring_z21)), 0) AS z21
    FROM prototype2.trajectory_cs
),

-- ============================================================
-- TRAJECTORY SUPERCOVER
-- ============================================================
traj_s AS (
    SELECT
        COUNT(*) AS rec,
        COALESCE(SUM(cardinality(cellstring_z13)), 0) AS z13,
        COALESCE(SUM(cardinality(cellstring_z17)), 0) AS z17,
        COALESCE(SUM(cardinality(cellstring_z21)), 0) AS z21
    FROM prototype2.trajectory_supercover_cs
),

-- ============================================================
-- STOP POLYGONS
-- ============================================================
stop_poly AS (
    SELECT
        COUNT(*) AS rec,
        COALESCE(SUM(ST_NPoints(geom)), 0) AS pts
    FROM prototype2.stop_poly
),

stop_poly_repeat AS (
    SELECT pts, rec FROM stop_poly
),

-- ============================================================
-- STOP CS
-- ============================================================
stop_cs AS (
    SELECT
        COUNT(*) AS rec,
        COALESCE(SUM(cardinality(cellstring_z13)), 0) AS z13,
        COALESCE(SUM(cardinality(cellstring_z17)), 0) AS z17,
        COALESCE(SUM(cardinality(cellstring_z21)), 0) AS z21
    FROM prototype2.stop_cs
)

-- ============================================================
-- OUTPUT SECTION
-- ============================================================
SELECT 'traj_z13' AS label,
       (SELECT pts FROM traj_ls_repeat) AS ls,
       (SELECT z13 FROM traj_b) AS b,
       (SELECT z13 FROM traj_s) AS s

UNION ALL

SELECT 'traj_z17',
       (SELECT pts FROM traj_ls_repeat),
       (SELECT z17 FROM traj_b),
       (SELECT z17 FROM traj_s)

UNION ALL

SELECT 'traj_z21',
       (SELECT pts FROM traj_ls_repeat),
       (SELECT z21 FROM traj_b),
       (SELECT z21 FROM traj_s)

UNION ALL

SELECT 'traj_records',
       (SELECT rec FROM traj_ls_repeat),
       (SELECT rec FROM traj_b),
       (SELECT rec FROM traj_s)

UNION ALL

SELECT 'stop_z13',
       (SELECT pts FROM stop_poly_repeat),
       (SELECT z13 FROM stop_cs),
       NULL

UNION ALL

SELECT 'stop_z17',
       (SELECT pts FROM stop_poly_repeat),
       (SELECT z17 FROM stop_cs),
       NULL

UNION ALL

SELECT 'stop_z21',
       (SELECT pts FROM stop_poly_repeat),
       (SELECT z21 FROM stop_cs),
       NULL

UNION ALL

SELECT 'stop_records',
       (SELECT rec FROM stop_poly_repeat),
       (SELECT rec FROM stop_cs),
       NULL;

WITH
-- ============================================================
-- Bresenham statistics
-- ============================================================
b13 AS (
    SELECT
        'bres' AS method,
        'z13' AS zoom,
        MIN(cardinality(cellstring_z13)) AS min,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cardinality(cellstring_z13)) AS median,
        AVG(cardinality(cellstring_z13)) AS avg,
        MAX(cardinality(cellstring_z13)) AS max
    FROM prototype2.trajectory_cs
),
b17 AS (
    SELECT
        'bres',
        'z17',
        MIN(cardinality(cellstring_z17)),
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cardinality(cellstring_z17)),
        AVG(cardinality(cellstring_z17)),
        MAX(cardinality(cellstring_z17))
    FROM prototype2.trajectory_cs
),
b21 AS (
    SELECT
        'bres',
        'z21',
        MIN(cardinality(cellstring_z21)),
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cardinality(cellstring_z21)),
        AVG(cardinality(cellstring_z21)),
        MAX(cardinality(cellstring_z21))
    FROM prototype2.trajectory_cs
),

-- ============================================================
-- Supercover statistics
-- ============================================================
s13 AS (
    SELECT
        'super' AS method,
        'z13' AS zoom,
        MIN(cardinality(cellstring_z13)) AS min,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cardinality(cellstring_z13)) AS median,
        AVG(cardinality(cellstring_z13)) AS avg,
        MAX(cardinality(cellstring_z13)) AS max
    FROM prototype2.trajectory_supercover_cs
),
s17 AS (
    SELECT
        'super',
        'z17',
        MIN(cardinality(cellstring_z17)),
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cardinality(cellstring_z17)),
        AVG(cardinality(cellstring_z17)),
        MAX(cardinality(cellstring_z17))
    FROM prototype2.trajectory_supercover_cs
),
s21 AS (
    SELECT
        'super',
        'z21',
        MIN(cardinality(cellstring_z21)),
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cardinality(cellstring_z21)),
        AVG(cardinality(cellstring_z21)),
        MAX(cardinality(cellstring_z21))
    FROM prototype2.trajectory_supercover_cs
)

-- ============================================================
-- Final Output
-- ============================================================
SELECT * FROM b13
UNION ALL SELECT * FROM b17
UNION ALL SELECT * FROM b21
UNION ALL SELECT * FROM s13
UNION ALL SELECT * FROM s17
UNION ALL SELECT * FROM s21;

EXPLAIN ANALYZE
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_ls AS trajA,
    prototype2.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 4422
    AND ST_Intersects(trajA.geom, trajB.geom);

EXPLAIN ANALYZE
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_ls AS trajA,
    prototype2.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 4467
    AND ST_Intersects(trajA.geom, trajB.geom);

EXPLAIN ANALYZE
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_supercover_cs AS trajA,
    prototype2.trajectory_supercover_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 4467
    AND CST_Intersects(trajA.cellstring_z21, trajB.cellstring_z21);

-- ==========================================================
-- Visualize LineString containment with Supercover CellString
-- ==========================================================
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom AS original_trajectory,

    -- Decoded CellString as polygons at different zoom levels
    CST_AsMultiPolygon(cs.cellstring_z13, 13) AS cells_z13,
    CST_AsMultiPolygon(cs.cellstring_z17, 17) AS cells_z17,
    CST_AsMultiPolygon(cs.cellstring_z21, 21) AS cells_z21,

    -- Containment check (TRUE = contained, FALSE = violation)
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z13, 13), ls.geom) AS z13_contained,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z17, 17), ls.geom) AS z17_contained,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z21, 21), ls.geom) AS z21_contained,

    -- Parts of trajectory NOT covered (for visualization of violations)
    ST_Difference(ls.geom, CST_AsMultiPolygon(cs.cellstring_z13, 13)) AS z13_uncovered,
    ST_Difference(ls.geom, CST_AsMultiPolygon(cs.cellstring_z17, 17)) AS z17_uncovered,
    ST_Difference(ls.geom, CST_AsMultiPolygon(cs.cellstring_z21, 21)) AS z21_uncovered

FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_supercover_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id = 8403;

SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom AS trajectory_geom,
    st_length(ST_Transform(ls.geom, 3857)) as trajectory_length

FROM prototype2.trajectory_ls ls
WHERE ls.trajectory_id IN (
    6836, 13176, 5776, 5097, 2959, 107, 10561, 11731, 810, 11863, 11591, 3285,
    6174, 4467, 10187, 10585, 2340, 7118, 1467, 11514, 12907, 9659, 9636, 353,
    3198, 9869, 1311, 7787, 4013, 10342, 8940, 12138, 4029, 11767, 6395, 12408,
    7648, 10815, 127, 2816, 6084, 8630, 9355, 7055, 8810, 13093, 10790, 8945,
    2446, 3349, 8310, 11082, 8717, 12807, 419, 1488, 4833, 11415, 11211, 12072,
    6679, 12405, 4949, 5059, 8309, 2853, 412, 7276, 3047, 440, 10802, 8907,
    10374, 1757, 5102, 9343, 9492, 2989, 1511, 4044, 10911, 10350, 9145, 12947,
    1178, 1762, 12402, 8992, 10700, 1783, 12130, 11136, 2524, 12518, 2644, 9778,
    10903, 517, 9793, 454, 9850, 4174, 6655, 9738, 13072, 1286, 6182, 12782,
    8529, 6669, 7535, 415, 519, 9896, 11119, 10745, 45, 724, 9309, 6338, 10195,
    13135, 12291, 12144, 12536, 8126, 6592, 6619, 12922, 1744, 9965, 4213, 7057,
    10116, 10245, 5636, 5762, 12388, 12003, 9957, 1522, 2525, 4246, 10264, 11722,
    9621, 10396, 8280, 1194, 6510, 11630, 7360, 5683, 10104, 13035, 6713, 4881,
    8836, 3282, 11564, 3432, 9889, 6235, 10840, 841, 10444, 9352, 9629, 11461,
    2582, 805, 6048, 12224, 6895, 5068, 10449, 1656, 10130, 12178, 437, 4184,
    3576, 11542, 12357, 8617, 1540, 4771, 11358, 896, 9519, 3905, 10528, 8470,
    367, 12119, 4239, 140, 5966, 3069, 3490, 11549, 7581, 12564, 10755, 11909,
    1405, 11724, 13129, 10467, 736, 9725, 6958, 8352, 6020, 10634, 13020, 12134,
    8539, 9306, 10112, 10115, 12838, 7483, 7745, 10927, 4116, 10816, 344, 10602,
    8286, 3273, 1514, 12569, 4090, 10642, 12946, 3825, 6276, 11612, 6854, 10376,
    2761, 2495, 9581, 9895, 12989, 3442, 10157, 144, 10477, 2828, 9029, 1469,
    8770, 12430, 12517, 5112, 434, 5001, 6239, 13157, 10898, 9805, 8590, 4034,
    8361, 12455, 11973, 11916, 12690, 10839, 1450, 1706, 12616, 9039, 7330, 8397,
    1753, 4641, 10486, 13312, 5055, 7336, 6203, 12139, 6603, 3994, 8033, 6232,
    10724, 6994, 12508, 5711, 9617, 7980, 11662, 10935, 9999, 9553, 11689, 8282,
    12264, 10297, 12490, 10521, 812, 3413, 6230, 3487, 9956, 4887, 3812, 9908,
    8692, 5842, 139, 8398, 2955, 2315, 12726, 6616, 818, 9789, 7402, 198, 8248,
    3203, 1537, 842, 4694, 7019, 1460, 11400, 2851, 1741, 13099, 6400, 1109,
    10482, 8297, 11197, 1841, 7991, 10537, 4210, 8830, 12533, 8587, 897, 8336,
    13143, 6561, 4645, 8817, 12145, 5747, 11607, 11331, 9102, 10474, 10024, 6778,
    12876, 9982, 12958, 4180, 9331, 6731, 3303, 732, 8582, 1441, 7077, 13127,
    11409, 12484, 4704, 5745, 6357, 5939, 613, 8269, 11658, 4584, 11042, 9832,
    4725, 4726, 235, 315, 9211, 3579, 6394, 5621, 3544, 11218, 9131, 12023, 6462, 12803
)
ORDER BY trajectory_length;

-- Query trajectory LineString (trajA)
SELECT
    8403 AS trajectory_id,
    'query' AS role,
    ls.geom AS trajectory_geom
FROM prototype2.trajectory_ls ls
WHERE ls.trajectory_id = 8403

UNION ALL

-- All intersecting trajectories' LineStrings (trajB)
SELECT
    trajB.trajectory_id,
    'result' AS role,
    ls.geom AS trajectory_geom
FROM prototype2.trajectory_supercover_cs trajA
JOIN prototype2.trajectory_supercover_cs trajB
    ON trajA.trajectory_id <> trajB.trajectory_id
    AND CST_Intersects(trajA.cellstring_z21, trajB.cellstring_z21)
JOIN prototype2.trajectory_ls ls ON trajB.trajectory_id = ls.trajectory_id
WHERE trajA.trajectory_id = 8403;

EXPLAIN ANALYZE
SELECT
    traj.trajectory_id
FROM
    prototype2.trajectory_supercover_cs AS traj,
    benchmark.area_cs AS area
WHERE area.area_id = 3
    AND CST_Intersects(traj.cellstring_z21, area.cellstring_z21);

EXPLAIN ANALYZE
SELECT
    traj.trajectory_id
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.area_poly AS area
WHERE area.area_id = 3
    AND ST_Intersects(traj.geom, area.geom);


SELECT pg_size_pretty (
        pg_database_size ('dw')
    );

SELECT pg_size_pretty (
        pg_database_size ('postgres')
    );
