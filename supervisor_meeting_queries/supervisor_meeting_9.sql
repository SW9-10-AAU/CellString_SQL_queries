-- Længden af CellString (Bresenham vs Supercover)
SELECT
    ROUND(AVG(arr_len), 1)                   AS avg_length,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY arr_len) AS median_length,
    MIN(arr_len)                             AS min_length,
    MAX(arr_len)                             AS max_length
FROM (
    SELECT COALESCE(array_length(cellstring_z21, 1), 0) AS arr_len
    FROM prototype2.trajectory_cs
--     FROM prototype2.trajectory_supercover_cs
) t;


-- Størrelsen af CellString (områder)
SELECT
    area_id,
    name,
    cardinality(cellstring_z21) as num_cells_z21,
    cardinality(cellstring_z17) as num_cells_z17,
    cardinality(cellstring_z13) as num_cells_z13
FROM benchmark.area_cs
ORDER BY num_cells_z21 DESC;


-- TRAJ: Visualisering af CellString på forskellige zoomniveauer + LineString
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom AS trajectory_geom,
    draw_cellstring(cs.cellstring_z13, 13) AS cells_z13,
    draw_cellstring(cs.cellstring_z17, 17) AS cells_z17,
    draw_cellstring(cs.cellstring_z21, 21) AS cells_z21
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_supercover_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id IN (8403);

-- STOP: Visualisering af CellString på forskellige zoomniveauer + LineString
SELECT
    ls.stop_id,
    ls.mmsi,
    ls.geom AS trajectory_geom,
    draw_cellstring(cs.cellstring_z13, 13) AS cells_z13,
    draw_cellstring(cs.cellstring_z17, 17) AS cells_z17,
    draw_cellstring(cs.cellstring_z21, 21) AS cells_z21
FROM prototype2.stop_poly ls
JOIN prototype2.stop_cs cs
    ON ls.stop_id = cs.stop_id
WHERE ls.stop_id IN (4026);


-- Visualisering af trajs + stops for et MMSI
-- visualise_trajectories_and_stops_by_mmsi.sql


-- Hausdorff Distance mellem dekodet CellString og original LineString
-- visualise_decoded_cellstring_to_linestring.sql