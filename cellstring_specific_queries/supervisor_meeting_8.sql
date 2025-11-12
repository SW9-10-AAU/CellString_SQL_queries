-- Antallet af trajectories og stops i de to prototyper
SELECT
    (SELECT COUNT(*) FROM prototype1.trajectory_ls) AS prot1_traj_count,
    (SELECT COUNT(*) FROM prototype2.trajectory_ls) AS prot2_traj_count,
    (SELECT COUNT(*) FROM prototype1.stop_poly)     AS prot1_stop_count,
    (SELECT COUNT(*) FROM prototype2.stop_poly)     AS prot2_stop_count;

-- Størrelsen af CellString (trajectories) prototype 1
SELECT
    ROUND(AVG(COALESCE(array_length(prot1.cellstring, 1), 0)), 1) AS avg_cellstring_prot1_z21_length,
    MIN(COALESCE(array_length(prot1.cellstring, 1), 0))           AS min_cellstring_prot1_z21_length,
    MAX(COALESCE(array_length(prot1.cellstring, 1), 0))           AS max_cellstring_prot1_z21_length
FROM
    prototype1.trajectory_cs as prot1;

-- Størrelsen af CellString (trajectories) prototype 2
SELECT
    ROUND(AVG(COALESCE(array_length(cellstring_z21, 1), 0)), 1) AS avg_cellstring_prot2_z21_length,
    MIN(COALESCE(array_length(cellstring_z21, 1), 0))           AS min_cellstring_prot2_z21_length,
    MAX(COALESCE(array_length(cellstring_z21, 1), 0))           AS max_cellstring_prot2_z21_length,
    ROUND(AVG(COALESCE(array_length(cellstring_z13, 1), 0)), 1) AS avg_cellstring_prot2_z13_length,
    MIN(COALESCE(array_length(cellstring_z13, 1), 0))           AS min_cellstring_prot2_z13_length,
    MAX(COALESCE(array_length(cellstring_z13, 1), 0))           AS max_cellstring_prot2_z13_length
FROM
    prototype2.trajectory_cs as prot2;


-- Størrelsen af CellString (områder)
SELECT
    area_id,
    name,
    cardinality(cellstring_z21) as num_cells_z21,
    cardinality(cellstring_z13) as num_cells_z13
FROM benchmark.area_cs
ORDER BY num_cells_z21 DESC;



-- Trajectories der krydser et område (Helsingør-Helsingborg)
SELECT DISTINCT
   traj.trajectory_id
FROM
   prototype2.trajectory_ls AS traj,
   benchmark.area_poly as area
WHERE
   area.area_id = 3
   AND ST_Intersects(traj.geom, area.geom);

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT
   traj.trajectory_id
FROM
   prototype2.trajectory_cs AS traj,
   benchmark.area_cs AS area
WHERE
   area.area_id = 3
   AND traj.cellstring_z13 && area.cellstring_z13;
--    AND traj.cellstring_z21 && area.cellstring_z21;


-- Trajectories der krydser et langt trajectory
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_ls AS trajA,
    prototype2.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 28749
    AND ST_Intersects(trajA.geom, trajB.geom);

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT JSON)
SELECT DISTINCT
   trajB.trajectory_id
FROM
   prototype2.trajectory_cs AS trajA,
   prototype2.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
   AND trajA.trajectory_id = 28749
--    AND trajA.cellstring_z13 && trajB.cellstring_z13;
   AND trajA.cellstring_z21 && trajB.cellstring_z21;