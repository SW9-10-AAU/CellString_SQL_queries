--- ST_ version (~4s) = 1998 trajectories ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype1.trajectory_ls AS trajA,
    prototype1.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 103078
    AND ST_Intersects(trajA.geom, trajB.geom);

--- CellString version (~9s) = 1874 trajectories ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype1.trajectory_cs AS trajA,
    prototype1.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 103078
    AND CST_Intersects(trajA.cellstring, trajB.cellstring);