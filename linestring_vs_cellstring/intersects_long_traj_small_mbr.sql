-- Longest trajectory (trajectory_id = 9133) consists of 76,822 points / 348,230 cells
-- mmsi 219000429 (Rødby-Putgarden ferry)
SELECT *
FROM prototype2.trajectory_ls
WHERE trajectory_id = 9133;

--- ST_ version (~1s) = 763 trajectories ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_ls AS trajA,
    prototype2.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 9133
    AND ST_Intersects(trajA.geom, trajB.geom);

--- Prototype 1 CellString version (~1m 7s) = 767 trajectories ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_cs AS trajA,
    prototype2.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 9133
    AND CST_Intersects(trajA.cellstring, trajB.cellstring);

--- Prototype 2 CellString version (~7s) = 767 trajectories ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_cs AS trajA,
    prototype2.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 9133
    AND CST_Intersects(trajA.cellstring, trajB.cellstring);
