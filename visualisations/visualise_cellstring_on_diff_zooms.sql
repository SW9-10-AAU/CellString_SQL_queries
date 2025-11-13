-- ==========================================================
-- Test trajectory query using draw_cellstring (zoom 21)
-- ==========================================================
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom               AS trajectory_geom,
    draw_cellstring(cs.cellstring_z21, 21) AS trajectory_cells
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id IN (8);


-- ==========================================================
-- Test trajectory query using draw_cellstring (zoom 17)
-- ==========================================================
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom               AS trajectory_geom,
    draw_cellstring(cs.cellstring_z17, 17) AS trajectory_cells
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id IN (8);


-- ==========================================================
-- Test trajectory query using draw_cellstring (zoom 13)
-- ==========================================================
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom               AS trajectory_geom,
    draw_cellstring(cs.cellstring_z13, 13) AS trajectory_cells
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id IN (8);


-- ==========================================================
-- Trajectory query: return all zooms in one row
-- ==========================================================
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom AS trajectory_geom,
    draw_cellstring(cs.cellstring_z13, 13) AS cells_z13,
    draw_cellstring(cs.cellstring_z17, 17) AS cells_z17,
    draw_cellstring(cs.cellstring_z21, 21) AS cells_z21
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id IN (8);


-- ==========================================================
-- Test stop query using draw_cellstring (zoom 21)
-- ==========================================================
SELECT
    ls.stop_id,
    ls.mmsi,
    ls.geom               AS stop_geom,
    draw_cellstring(cs.cellstring_z21, 21) AS stop_cells
FROM prototype2.stop_poly ls
JOIN prototype2.stop_cs cs
    ON ls.stop_id = cs.stop_id
WHERE ls.stop_id IN (5291);


-- ==========================================================
-- Test stop query using draw_cellstring (zoom 17)
-- ==========================================================
SELECT
    ls.stop_id,
    ls.mmsi,
    ls.geom               AS stop_geom,
    draw_cellstring(cs.cellstring_z17, 17) AS stop_cells
FROM prototype2.stop_poly ls
JOIN prototype2.stop_cs cs
    ON ls.stop_id = cs.stop_id
WHERE ls.stop_id IN (5291);


-- ==========================================================
-- Test stop query using draw_cellstring (zoom 13)
-- ==========================================================
SELECT
    ls.stop_id,
    ls.mmsi,
    ls.geom               AS stop_geom,
    draw_cellstring(cs.cellstring_z13, 13) AS stop_cells
FROM prototype2.stop_poly ls
JOIN prototype2.stop_cs cs
    ON ls.stop_id = cs.stop_id
WHERE ls.stop_id IN (5291);

-- ==========================================================
-- Stop query: return all zooms in one row
-- ==========================================================
SELECT
    ls.stop_id,
    ls.mmsi,
    ls.geom AS stop_geom,
    draw_cellstring(cs.cellstring_z13, 13) AS cells_z13,
    draw_cellstring(cs.cellstring_z17, 17) AS cells_z17,
    draw_cellstring(cs.cellstring_z21, 21) AS cells_z21
FROM prototype2.stop_poly ls
JOIN prototype2.stop_cs cs
    ON ls.stop_id = cs.stop_id
WHERE ls.stop_id IN (489);
