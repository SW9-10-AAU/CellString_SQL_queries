-- Trajectory intersects with trajectory, cartesian product (simple query)

--- ST_ version (1.4s) ---
SELECT
    trajA.trajectory_id,
    trajB.trajectory_id
FROM
    prototype1.trajectory_ls AS trajA,
    prototype1.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.mmsi <> trajB.mmsi
    AND ST_Intersects(trajA.geom, trajB.geom);

--- CellString version (750ms) ---
SELECT
    trajA.trajectory_id,
    trajB.trajectory_id
FROM
    prototype1.trajectory_cs AS trajA,
    prototype1.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.mmsi <> trajB.mmsi
    AND CST_Intersects(trajA.cellstring, trajB.cellstring);