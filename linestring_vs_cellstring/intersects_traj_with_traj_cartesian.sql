-- Trajectory intersects with trajectory, cartesian product (simple query)

--- ST_ version (1.4s) ---
SELECT
    trajA.trajectory_id,
    trajB.trajectory_id
FROM
    prototype2.trajectory_ls AS trajA,
    prototype2.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.mmsi <> trajB.mmsi
    AND ST_Intersects(trajA.geom, trajB.geom);

--- CellString version (750ms) ---
SELECT
    trajA.trajectory_id,
    trajB.trajectory_id
FROM
    prototype2.trajectory_cs AS trajA,
    prototype2.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.mmsi <> trajB.mmsi
    AND CST_Intersects(trajA.cellstring_z21, trajB.cellstring_z21);