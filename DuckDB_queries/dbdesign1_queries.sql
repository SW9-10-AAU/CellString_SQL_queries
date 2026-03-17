--Intersects BOOL (Returns true if A and B have no cells in common)
WITH a_cells AS (SELECT cell_z21
                 FROM db_design1_linecover_queriestest.trajectory_cs
                 WHERE trajectory_id = 33),
     b_cells AS (SELECT cell_z21
                 FROM db_design1_linecover_queriestest.trajectory_cs
                 WHERE trajectory_id = 1252)
SELECT EXISTS (SELECT cell_z21
               FROM a_cells
               INTERSECT
               SELECT cell_z21
               FROM b_cells) AS intersects;


--Intersects (trajectories)
WITH target_cells AS (SELECT cell_z21
                      FROM db_design1_linecover_queriestest.trajectory_cs
                      WHERE trajectory_id = 33)
SELECT DISTINCT t.trajectory_id
FROM db_design1_linecover_queriestest.trajectory_cs t
         JOIN target_cells tc
              ON t.cell_z21 = tc.cell_z21
WHERE t.trajectory_id <> 33;

--Intersects (trajectories - stop)
WITH target_cells AS (SELECT cell_z21
                      FROM db_design1_linecover_queriestest.trajectory_cs
                      WHERE trajectory_id = 33)
SELECT DISTINCT t.stop_id
FROM db_design1_linecover_queriestest.stop_cs t
         JOIN target_cells tc
              ON t.cell_z21 = tc.cell_z21;

--Intersects with time (trajectories)
WITH target_cells AS (SELECT cell_z21, ts
                      FROM db_design1_linecover_queriestest.trajectory_cs
                      WHERE trajectory_id = 33)
SELECT DISTINCT t.trajectory_id,
FROM db_design1_linecover_queriestest.trajectory_cs t
         JOIN target_cells tc
              ON t.cell_z21 = tc.cell_z21
WHERE t.trajectory_id <> 33
  AND t.ts BETWEEN tc.ts - INTERVAL '500 minutes'
  AND tc.ts + INTERVAL '500 minutes';


--Intersection(trajectories)
WITH target_cells AS (SELECT cell_z21,
                      FROM db_design1_linecover_queriestest.trajectory_cs
                      WHERE trajectory_id = 33)
SELECT DISTINCT t.trajectory_id,
                t.cell_z21 as overlap_cells,
FROM db_design1_linecover_queriestest.trajectory_cs t
         JOIN target_cells tc
              ON t.cell_z21 = tc.cell_z21
WHERE t.trajectory_id <> 33;


--Intersection with time (trajectories)
WITH target_cells AS (SELECT cell_z21, ts, mmsi
                      FROM db_design1_linecover_queriestest.trajectory_cs
                      WHERE trajectory_id = 33)
SELECT DISTINCT t.trajectory_id,
                tc.mmsi                            AS this_ship,
                t.mmsi                             AS other_ship,
                t.cell_z21                         as in_cell,
                EXTRACT(EPOCH FROM (t.ts - tc.ts)) AS time_diff_seconds
FROM db_design1_linecover_queriestest.trajectory_cs t
         JOIN target_cells tc
              ON t.cell_z21 = tc.cell_z21
WHERE t.trajectory_id <> 33
  AND t.ts BETWEEN tc.ts - INTERVAL '5000 minutes'
  AND tc.ts + INTERVAL '5000 minutes'
ORDER BY time_diff_seconds ASC;

--test count
select count(cell_z21) from db_design1_linecover_queriestest.trajectory_cs where trajectory_id =32;
--UNION
WITH a_cells AS (SELECT cell_z21, ts
                 FROM db_design1_linecover_queriestest.trajectory_cs
                 WHERE trajectory_id = 33),
     b_cells AS (SELECT cell_z21, ts
                 FROM db_design1_linecover_queriestest.trajectory_cs
                 WHERE trajectory_id = 32)
SELECT cell_z21, ts
FROM a_cells
UNION
SELECT cell_z21, ts
FROM b_cells;

--DIFFERENCE (Returns cells in trajectory A that are NOT in trajectory B.)
SELECT DISTINCT trajectory_id, cell_z21
FROM db_design1_linecover_queriestest.trajectory_cs
WHERE trajectory_id = 33  -- replace with the trajectory ID for A
  AND cell_z21 NOT IN (
      SELECT cell_z21
      FROM db_design1_linecover_queriestest.trajectory_cs
      WHERE trajectory_id = 1251  -- replace with trajectory ID for B
  );

-- Returns true if A contains B (all B’s cells are in A and they overlap)
WITH b_cells AS (
    SELECT cell_z21
    FROM db_design1_linecover_queriestest.trajectory_cs
    WHERE trajectory_id = 33
),
a_cells AS (
    SELECT cell_z21
    FROM db_design1_linecover_queriestest.trajectory_cs
    WHERE trajectory_id = 33
)
SELECT
    CASE
        WHEN COUNT(*) = 0 THEN TRUE   -- all B cells are in A
        ELSE FALSE                    -- some B cells missing from A
    END AS a_contains_b
FROM b_cells b
WHERE b.cell_z21 NOT IN (SELECT cell_z21 FROM a_cells);


--disjoint (Returns true if A and B have no cells in common)
WITH a_cells AS (
    SELECT cell_z21
    FROM db_design1_linecover_queriestest.trajectory_cs
    WHERE trajectory_id = 33
),
b_cells AS (
    SELECT cell_z21
    FROM db_design1_linecover_queriestest.trajectory_cs
    WHERE trajectory_id = 1251
)
SELECT
    NOT EXISTS (
        SELECT cell_z21 FROM a_cells
        INTERSECT
        SELECT cell_z21 FROM b_cells
    ) AS is_disjoint;




