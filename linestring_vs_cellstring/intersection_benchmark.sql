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

-- INTERSECTION OF 2 TRAJECTORIES AS LINESTRING VS CELLSTRING

-- 100 points trajectory_ids: 366 and 453
-- st_ version (~239ms)
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    ST_Intersection(
        (SELECT geom FROM prototype1.trajectory_ls WHERE trajectory_id = 366),
        (SELECT geom FROM prototype1.trajectory_ls WHERE trajectory_id = 453)
    ) AS intersection_linestring;

-- cst_ version (~246ms)
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    CST_Intersection(
        (SELECT cellstring FROM prototype1.trajectory_cs WHERE trajectory_id = 366),
        (SELECT cellstring FROM prototype1.trajectory_cs WHERE trajectory_id = 453)
    ) AS intersection_cellstring;

-- 1000 points trajectory_ids: 4727 and 91737
-- st_ version (~1488ms)
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    ST_Intersection(
        (SELECT geom FROM prototype1.trajectory_ls WHERE trajectory_id = 4727),
        (SELECT geom FROM prototype1.trajectory_ls WHERE trajectory_id = 91737)
    ) AS intersection_linestring;

-- cst_ version (~1935ms)
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    CST_Intersection(
        (SELECT cellstring FROM prototype1.trajectory_cs WHERE trajectory_id = 4727),
        (SELECT cellstring FROM prototype1.trajectory_cs WHERE trajectory_id = 91737)
    ) AS intersection_cellstring;

-- 10000 points trajectory_ids: 10648 and 57048
-- st_ version (~3892ms)
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    ST_Intersection(
        (SELECT geom FROM prototype1.trajectory_ls WHERE trajectory_id = 10648),
        (SELECT geom FROM prototype1.trajectory_ls WHERE trajectory_id = 57048)
    ) AS intersection_linestring;

-- cst_ version (~5580ms)
EXPLAIN (ANALYZE, COSTS, BUFFERS)
SELECT
    CST_Intersection(
        (SELECT cellstring FROM prototype1.trajectory_cs WHERE trajectory_id = 10648),
        (SELECT cellstring FROM prototype1.trajectory_cs WHERE trajectory_id = 57048)
    ) AS intersection_cellstring;