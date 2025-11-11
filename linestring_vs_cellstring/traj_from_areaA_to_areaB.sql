-- Trajectory intersects with areaA and areaB (has sailed from areaA --> areaB)

--- ST_ version (Hals-Egense to Helsingør-Helsingborg) (1.5s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi,
    traj.geom
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.area_poly as areaA,
    benchmark.area_poly as areaB
WHERE areaA.area_id = 2
    AND areaB.area_id = 3
    AND ST_Intersects(traj.geom, areaA.geom)
    AND ST_Intersects(traj.geom, areaB.geom);

--- CST_ version (Hals-Egense to Helsingør-Helsingborg) (8s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi,
    traj.cellstring
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs as areaA,
    benchmark.area_cs as areaB
WHERE areaA.area_id = 2
    AND areaB.area_id = 3
    AND CST_Intersects(traj.cellstring, areaA.cellstring)
    AND CST_Intersects(traj.cellstring, areaB.cellstring);

