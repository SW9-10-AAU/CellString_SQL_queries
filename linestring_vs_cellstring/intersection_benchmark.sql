--- Testing on Hals-Egense area (area_id = 2)

--- ST_ version (3s)---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    traj.trajectory_id,
    area.area_id,
    ST_Intersection(traj.geom, area.geom) AS intersection
FROM
    prototype1.trajectory_ls AS traj,
    benchmark.area_poly AS area
WHERE area.area_id = 2
    AND ST_Intersects(traj.geom, area.geom);

--- CST_ version (824ms) ---
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    traj.trajectory_id,
    area.area_id,
    CST_Intersection(traj.cellstring, area.cellstring) AS intersection
FROM
    prototype1.trajectory_cs AS traj,
    benchmark.area_cs AS area
WHERE area.area_id = 2
    AND CST_Intersects(traj.cellstring, area.cellstring);