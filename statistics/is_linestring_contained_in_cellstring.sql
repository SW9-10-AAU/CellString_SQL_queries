-- Bresenham
SELECT
    ls.trajectory_id,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z13, 13), ls.geom) AS z13_contains,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z17, 17), ls.geom) AS z17_contains,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z21, 21), ls.geom) AS z21_contains
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id = 8403;

-- Supercover
SELECT
    ls.trajectory_id,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z13, 13), ls.geom) AS z13_contains,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z17, 17), ls.geom) AS z17_contains,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z21, 21), ls.geom) AS z21_contains
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_supercover_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id = 8403;


-- Visualisation
SELECT
    ls.geom AS trajectory_geom,
    CST_AsMultiPolygon(cs.cellstring_z13, 13) AS cells_z13,
    CST_AsMultiPolygon(cs.cellstring_z17, 17) AS cells_z17,
    CST_AsMultiPolygon(cs.cellstring_z21, 21) AS cells_z21
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
-- JOIN prototype2.trajectory_supercover_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id = 8403;


