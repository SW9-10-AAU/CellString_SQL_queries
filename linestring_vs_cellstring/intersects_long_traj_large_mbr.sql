--- ST_ version (~4s) = 1998 trajectories ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_ls AS trajA,
    prototype2.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 103078
    AND ST_Intersects(trajA.geom, trajB.geom);

--- CellString version (~9s) = 1874 trajectories ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_cs AS trajA,
    prototype2.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 103078
    AND CST_Intersects(trajA.cellstring, trajB.cellstring);

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT
    trajB.trajectory_id
FROM
    prototype2.trajectory_cs AS trajA,
    prototype2.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.trajectory_id = 28749
    AND trajA.cellstring_z13 && trajB.cellstring_z13
    AND CST_Intersects(trajA.cellstring_z21, trajB.cellstring_z21);



EXPLAIN
WITH area AS MATERIALIZED (
    SELECT cellstring_z13, cellstring_z21
    FROM benchmark.area_cs
    WHERE area_id = 3
),
coarse AS MATERIALIZED (
    SELECT traj.trajectory_id
    FROM prototype2.trajectory_cs AS traj, area
    WHERE traj.cellstring_z13 && area.cellstring_z13
)
SELECT t.trajectory_id, t.mmsi
FROM prototype2.trajectory_cs AS t
JOIN coarse USING (trajectory_id),
     area
WHERE CST_Intersects(t.cellstring_z21, area.cellstring_z21);  -- no index here