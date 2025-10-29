-- Trajectory intersects with area (simple query)

--- ST_ version (Hals-Egense) (1.5s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype1.trajectory_ls AS traj,
    benchmark.area_poly as area
WHERE
    area.area_id = 2
    AND ST_Intersects(traj.geom, area.geom);

--- CellString version (Hals-Egense) (0.36s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype1.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 2
    AND CST_Intersects(traj.cellstring, area.cellstring);



--- ST_ version (Helsingør-Helsingborg) (1.5s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype1.trajectory_ls AS traj,
    benchmark.area_poly as area
WHERE
    area.area_id = 3
    AND ST_Intersects(traj.geom, area.geom);

--- CellString version (Helsingør-Helsingborg) (8s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype1.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 3
    AND CST_Intersects(traj.cellstring, area.cellstring);



--- ST_ version (Læsø) (2s)---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype1.trajectory_ls AS traj,
    benchmark.area_poly as area
WHERE
    area.area_id = 1
    AND ST_Intersects(traj.geom, area.geom);

--- CellString version (Læsø) ---
--- !! not able to execute !!
-- TODO: Add another zoom level (e.g. zoom level 13 and filter with this in the where clause)
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype1.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 1
    AND CST_Intersects(traj.cellstring, area.cellstring);
