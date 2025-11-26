-- Via query: Find all trajectories that have sailed through crossing A, B and C.

----- VIA QUERY 1: Skagen, Storebælt and Bornholm -----

--- ST_ version (Skagen, Storebælt and Bornholm) (2.1s) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.crossing_ls as crossingA,
    benchmark.crossing_ls as crossingB,
    benchmark.crossing_ls as crossingC
WHERE crossingA.crossing_id = 1 -- Skagen
    AND crossingB.crossing_id = 2 -- Storebælt
    AND crossingC.crossing_id = 4 -- Bornholm
    AND ST_Intersects(traj.geom, crossingA.geom)
    AND ST_Intersects(traj.geom, crossingB.geom)
    AND ST_Intersects(traj.geom, crossingC.geom);

--- CST_ Bresenham version (Skagen, Storebælt and Bornholm) (z21 = 48s, z17 = 700ms, z13 = 370ms) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.crossing_cs as crossingA,
    benchmark.crossing_cs as crossingB,
    benchmark.crossing_cs as crossingC
WHERE crossingA.crossing_id = 1 -- Skagen
    AND crossingB.crossing_id = 2 -- Storebælt
    AND crossingC.crossing_id = 4 -- Bornholm
--     AND CST_Intersects(traj.cellstring_z21, crossingA.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingB.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingC.cellstring_z21)
    AND CST_Intersects(traj.cellstring_z17, crossingA.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingB.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingC.cellstring_z17)
--     AND CST_Intersects(traj.cellstring_z13, crossingA.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingB.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingC.cellstring_z13)
;

--- CST_ Supercover version (Skagen, Storebælt and Bornholm) (z21 = 1m 14s, z17 = 730ms, z13 = 400ms) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_supercover_cs AS traj,
    benchmark.crossing_cs as crossingA,
    benchmark.crossing_cs as crossingB,
    benchmark.crossing_cs as crossingC
WHERE crossingA.crossing_id = 1 -- Skagen
    AND crossingB.crossing_id = 2 -- Storebælt
    AND crossingC.crossing_id = 4 -- Bornholm
--     AND CST_Intersects(traj.cellstring_z21, crossingA.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingB.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingC.cellstring_z21)
    AND CST_Intersects(traj.cellstring_z17, crossingA.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingB.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingC.cellstring_z17)
--     AND CST_Intersects(traj.cellstring_z13, crossingA.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingB.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingC.cellstring_z13)
;

----- VIA QUERY 2: Skagen, Helsingør-Helsingborg and Bornholm -----

--- ST_ version (Skagen, Helsingør-Helsingborg and Bornholm) (2.3s) ---
SELECT
    traj.trajectory_id,
--     traj.geom,
    traj.mmsi
FROM
    prototype2.trajectory_ls AS traj,
    benchmark.crossing_ls as crossingA,
    benchmark.crossing_ls as crossingB,
    benchmark.crossing_ls as crossingC
WHERE crossingA.crossing_id = 1 -- Skagen
    AND crossingB.crossing_id = 3 -- Helsingør-Helsingborg
    AND crossingC.crossing_id = 4 -- Bornholm
    AND ST_Intersects(traj.geom, crossingA.geom)
    AND ST_Intersects(traj.geom, crossingB.geom)
    AND ST_Intersects(traj.geom, crossingC.geom);


--- CST_ Bresenham version (Skagen, Helsingør-Helsingborg and Bornholm) (z21 = 44s, z17 = 600ms, z13 = 400ms) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.crossing_cs as crossingA,
    benchmark.crossing_cs as crossingB,
    benchmark.crossing_cs as crossingC
WHERE crossingA.crossing_id = 1 -- Skagen
    AND crossingB.crossing_id = 3 -- Helsingør-Helsingborg
    AND crossingC.crossing_id = 4 -- Bornholm
--     AND CST_Intersects(traj.cellstring_z21, crossingA.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingB.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingC.cellstring_z21)
    AND CST_Intersects(traj.cellstring_z17, crossingA.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingB.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingC.cellstring_z17)
--     AND CST_Intersects(traj.cellstring_z13, crossingA.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingB.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingC.cellstring_z13)
;

--- CST_ Supercover version (Skagen, Helsingør-Helsingborg and Bornholm) (z21 = 1m 8s, z17 = 660ms, z13 = 390ms) ---
SELECT
    traj.trajectory_id,
    traj.mmsi
FROM
    prototype2.trajectory_supercover_cs AS traj,
    benchmark.crossing_cs as crossingA,
    benchmark.crossing_cs as crossingB,
    benchmark.crossing_cs as crossingC
WHERE crossingA.crossing_id = 1 -- Skagen
    AND crossingB.crossing_id = 3 -- Helsingør-Helsingborg
    AND crossingC.crossing_id = 4 -- Bornholm
--     AND CST_Intersects(traj.cellstring_z21, crossingA.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingB.cellstring_z21)
--     AND CST_Intersects(traj.cellstring_z21, crossingC.cellstring_z21)
    AND CST_Intersects(traj.cellstring_z17, crossingA.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingB.cellstring_z17)
    AND CST_Intersects(traj.cellstring_z17, crossingC.cellstring_z17)
--     AND CST_Intersects(traj.cellstring_z13, crossingA.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingB.cellstring_z13)
--     AND CST_Intersects(traj.cellstring_z13, crossingC.cellstring_z13)
;