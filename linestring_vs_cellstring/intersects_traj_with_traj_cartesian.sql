-- Trajectory intersects with trajectory, cartesian product (simple query)

--- ST_ version ---
SELECT
    trajA.trajectory_id,
    trajB.trajectory_id
FROM
    prototype1.trajectory_ls AS trajA,
    prototype1.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
  AND ST_Intersects(trajA.geom, trajB.geom);

--- CellString version ---
SELECT
    trajA.trajectory_id,
    trajB.trajectory_id
FROM
    prototype1.trajectory_cs AS trajA,
    prototype1.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
  AND CST_Intersects(trajA.cellstring, trajB.cellstring);
