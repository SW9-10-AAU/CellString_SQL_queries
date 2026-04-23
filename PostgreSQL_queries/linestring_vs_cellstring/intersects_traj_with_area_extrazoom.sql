-- Trajectory intersects with area (simple query)

--- ST_ version (Hals-Egense) (1.5s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.area_poly as area
WHERE
    area.area_id = 2
    AND ST_Intersects(traj.geom, area.geom);

--- CellString version (Hals-Egense) (0.36s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 2
    AND CST_Intersects(traj.cellstring_z21, area.cellstring_z21);

-- Extra-zoom version (Hals-Egense) (0.5s) ---
WITH area AS (
    SELECT *
    FROM benchmark.area_cs as area
    WHERE area.area_id = 3
),
z13_trajectory AS (
    SELECT
        traj.trajectory_id,
        traj.mmsi,
        traj.cellstring_z21
    FROM prototype2.trajectory_cs as traj,
         area
    WHERE CST_Intersects(traj.cellstring_z13, area.cellstring_z13)
)
SELECT
    traj13.trajectory_id,
    traj13.mmsi
FROM
    z13_trajectory AS traj13
JOIN AREA ON CST_Intersects(traj13.cellstring_z21, area.cellstring_z21);


--- ST_ version (Helsingør-Helsingborg) (1.5s) ---
SELECT DISTINCT
    traj.trajectory_id
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.area_poly as area
WHERE
--     area.area_id = 22
    area.area_id = 3
    AND ST_Intersects(traj.geom, area.geom);

--- CellString version (Helsingør-Helsingborg) (8s) ---
SELECT DISTINCT
    traj.trajectory_id
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
--     area.area_id = 22
    area.area_id = 3
    AND CST_Intersects(traj.cellstring_z13,area.cellstring_z13);

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    traj.trajectory_id,
    traj.mmsi,
    traj.cellstring_z21
FROM prototype2.trajectory_cs AS traj
JOIN benchmark.area_cs AS area
  ON area.area_id = 3
 AND traj.cellstring_z13 && area.cellstring_z13;

EXPLAIN
WITH coarse_candidates AS (
    SELECT traj.trajectory_id,
           traj.mmsi,
           traj.cellstring_z21
    FROM prototype2.trajectory_cs AS traj
    JOIN benchmark.area_cs AS area
      ON area.area_id = 3
     AND traj.cellstring_z13 && area.cellstring_z13
)
SELECT c.trajectory_id, c.mmsi
FROM coarse_candidates AS c
JOIN benchmark.area_cs AS area
  ON area.area_id = 3
WHERE CST_Intersects(c.cellstring_z21, area.cellstring_z21);

SELECT
    trajectory_id,
    cardinality(t.cellstring_z13) as traj_cell_count_13,
    cardinality(t.cellstring_z21) as traj_cell_count_21,
    cardinality(a.cellstring_z21) as area_cell_count_21
FROM prototype2.trajectory_cs AS t,
     benchmark.area_cs AS a
WHERE a.area_id = 3
  AND t.cellstring_z13 && a.cellstring_z13
  AND CST_Intersects(t.cellstring_z21, a.cellstring_z21)
ORDER BY traj_cell_count_21 DESC;

SELECT
    trajectory_id,
    cardinality(t.cellstring_z13) as traj_cell_count_13,
    cardinality(t.cellstring_z21) as traj_cell_count_21,
    cardinality(a.cellstring_z21) as area_cell_count_21
FROM prototype2.trajectory_cs AS t,
     benchmark.area_cs AS a
WHERE a.area_id = 3
  AND t.cellstring_z13 && a.cellstring_z13
  AND CST_Intersects(t.cellstring_z21, a.cellstring_z21)
ORDER BY traj_cell_count_21 DESC;

-- Stage 1: Coarse filter using z13
EXPLAIN
WITH coarse_ids AS (
    SELECT traj.trajectory_id
    FROM prototype2.trajectory_cs AS traj
    JOIN benchmark.area_cs AS area
      ON area.area_id = 3
    WHERE traj.cellstring_z13 && area.cellstring_z13
)
-- Stage 2: Fine filter using z21, only for the candidates
SELECT t.trajectory_id, t.mmsi
FROM prototype2.trajectory_cs AS t
JOIN coarse_ids AS c
  ON t.trajectory_id = c.trajectory_id
JOIN benchmark.area_cs AS area
  ON area.area_id = 3
WHERE CST_Intersects(t.cellstring_z21, area.cellstring_z21);


--- ST_ version (Læsø) (2s)---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_ls AS traj,
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
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 1
    AND CST_Intersects(traj.cellstring_z21, area.cellstring_z21);

BEGIN;

CREATE TEMP TABLE coarse_ids ON COMMIT DROP AS
SELECT trajectory_id
FROM prototype2.trajectory_cs AS traj
JOIN benchmark.area_cs AS area
  ON area.area_id = 3
WHERE traj.cellstring_z13 && area.cellstring_z13;

ANALYZE coarse_ids;

SET LOCAL enable_bitmapscan = off;
SET LOCAL enable_seqscan = off;
SET LOCAL enable_hashjoin = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT t.trajectory_id, t.mmsi
FROM coarse_ids c
JOIN prototype2.trajectory_cs t USING (trajectory_id)
JOIN benchmark.area_cs area ON area.area_id = 3
WHERE CST_Intersects(t.cellstring_z21, area.cellstring_z21);


COMMIT;


EXPLAIN (ANALYZE, BUFFERS)
SELECT traj.trajectory_id, traj.mmsi
FROM prototype2.trajectory_cs traj
JOIN benchmark.area_cs area ON area.area_id = 3
WHERE traj.trajectory_id IN (
    SELECT trajectory_id
    FROM prototype2.trajectory_cs
    WHERE cellstring_z13 && area.cellstring_z13
)
AND CST_Intersects(traj.cellstring_z21, area.cellstring_z21);

SELECT traj.trajectory_id, traj.mmsi
FROM prototype2.trajectory_cs traj
JOIN benchmark.area_cs area ON area.area_id = 3
WHERE CST_Intersects(traj.cellstring_z13, area.cellstring_z13)