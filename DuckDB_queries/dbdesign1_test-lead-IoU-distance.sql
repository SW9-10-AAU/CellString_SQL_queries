
------------------------------------------------------------------------------------------------
---test queries
------------------------------------------------------------------------------------------------

SET VARIABLE target_vessle = 219000771;
--query results

WITH all_intervals AS (
    SELECT
        cell_z21,
        mmsi,
        trajectory_id,
        ts AS ts_start,
        LEAD(ts) OVER (PARTITION BY trajectory_id ORDER BY ts) AS ts_end
    FROM trajectory_cs
),
query_cellstring AS (
    SELECT * FROM all_intervals
    WHERE mmsi = getvariable('target_vessle')
),
candidate_cellstrings AS (
    SELECT * FROM all_intervals
    WHERE cell_z21 IN (SELECT cell_z21 FROM query_cellstring)
      AND mmsi <> getvariable('target_vessle')
)
SELECT
    c.trajectory_id AS cand_traj_id,
    q.trajectory_id AS query_traj_id,
    c.cell_z21,
    q.ts_start AS q_start,
    q.ts_end AS q_end,
    c.ts_start AS c_start,
    c.ts_end AS c_end,
    c.mmsi,
    q.mmsi
FROM candidate_cellstrings AS c
JOIN query_cellstring AS q ON c.cell_z21 = q.cell_z21
WHERE q.ts_start <= COALESCE(c.ts_end, c.ts_start)
  AND COALESCE(q.ts_end, q.ts_start) >= c.ts_start;

--visual
load spatial;
select *, st_astext(CS_CellAsPolygon(cell_z21, 21)) as geom from trajectory_cs where trajectory_id in (2450,2782);


---find som cases
WITH interval_data AS (
    SELECT
        mmsi,
        trajectory_id,
        cell_z21,
        ts AS ts_start,
        -- Get the exit time (arrival at next cell)
        LEAD(ts) OVER (PARTITION BY trajectory_id ORDER BY ts) AS ts_end
    FROM trajectory_cs
    -- OPTIONAL: Add a broad filter here (e.g., ts > '2026-01-01') to speed it up
)
SELECT
    a.cell_z21,
    a.mmsi AS mmsi_1,
    b.mmsi AS mmsi_2,
    a.trajectory_id AS traj_1,
    b.trajectory_id AS traj_2,
    -- Calculate the exact moment they both entered and the first one left
    GREATEST(a.ts_start, b.ts_start) AS overlap_start,
    LEAST(COALESCE(a.ts_end, a.ts_start), COALESCE(b.ts_end, b.ts_start)) AS overlap_end
FROM interval_data a
JOIN interval_data b ON a.cell_z21 = b.cell_z21
WHERE a.mmsi <> b.mmsi  -- 1. Eliminates self-matches and duplicate pairs (A-B vs B-A)
  -- 2. The core "Spatio-Temporal" overlap condition
  AND a.ts_start <= COALESCE(b.ts_end, b.ts_start)
  AND b.ts_start <= COALESCE(a.ts_end, a.ts_start);

SELECT ST_AsText(CS_CellAsPolygon(cell_z21, 21)) AS geom, cell_z21 FROM trajectory_cs WHERE trajectory_id IN (2503, 2504, 2505, 2507);

------------------------------------------------------------------------------------------------

CREATE OR REPLACE MACRO CS_IoU(cs_a, cs_b) AS TABLE (
    WITH intersection_stats AS (
        SELECT
            c.trajectory_id,
            COUNT(DISTINCT c.cell_z21) AS intersection_cnt
        FROM query_table(cs_b) c
        JOIN cs_a q ON c.cell_z21 = q.cell_z21
        GROUP BY c.trajectory_id
    ),
    candidate_counts AS (
        SELECT
            trajectory_id,
            COUNT(DISTINCT cell_z21) AS candidate_cnt
        FROM query_table(cs_b)
        GROUP BY trajectory_id
    ),
    query_count AS (
        SELECT COUNT(DISTINCT cell_z21) AS query_cnt
        FROM query_table(cs_a)
    )
    SELECT
        i.trajectory_id,
        i.intersection_cnt::FLOAT / (q.query_cnt + c.candidate_cnt - i.intersection_cnt)::FLOAT AS similarity_score
    FROM intersection_stats i
    JOIN candidate_counts c ON i.trajectory_id = c.trajectory_id
    CROSS JOIN query_count q
);


WITH cs_a AS (
    SELECT CS_GetParentCellId(cell_z21, 21, 13) as cell_z21 FROM trajectory_cs WHERE trajectory_id = 1666
),
cs_b AS (
    SELECT trajectory_id, CS_GetParentCellId(cell_z21, 21, 13) as cell_z21 FROM trajectory_cs WHERE mmsi = 265177000
)
SELECT * FROM CS_IoU(cs_a, cs_b)
ORDER BY similarity_score DESC;


load spatial;
select trajectory_id, mmsi, ST_astext(st_force2d(geom)) as traj from trajectory_ls where trajectory_id in (1666, 1667, 1662);

select trajectory_id, mmsi, ST_astext(CS_CellAsPolygon(CS_GetParentCellId(cell_z21, 21, 13),13)) as traj from trajectory_cs where trajectory_id in (1666, 1662, 1667);

select distinct trajectory_id from trajectory_cs where mmsi = 265177000;

-- precompute cellstring table as zoom lvl, for fasr KNN_decoded
CREATE OR REPLACE TEMP TABLE trajectory_decoded AS
SELECT
    trajectory_id,
    cell_z21,
    CS_CellIdToTileZXY(cell_z21, 21).x AS x,
    CS_CellIdToTileZXY(cell_z21, 21).y AS y
FROM trajectory_cs;


--KNN with cells (zoom 21) DEFAULT
WITH
cs_a AS (
    SELECT 1664470337539::BIGINT AS cell_z21
),
cs_b AS (
    SELECT *
    FROM trajectory_cs
)

SELECT *
FROM CS_KNN(cs_a, cs_b, 21, 10);

--KNN with cells (zoom 13)
WITH
cs_a AS (
    SELECT CS_GetParentCellId(1664470337539, 21, 13) AS cell_z21
),
cs_b AS (
    SELECT DISTINCT trajectory_id, CS_GetParentCellId(cell_z21, 21,13) AS cell_z21
    FROM trajectory_cs
)

SELECT *
FROM CS_KNN(cs_a, cs_b, 13, 15);


-- Using KNN-decoded cells table (but not implemented with different zoom lvls)
WITH
cs_a AS (
    SELECT
        CS_CellIdToTileZXY(1664470337539, 21).x AS x,
        CS_CellIdToTileZXY(1664470337539, 21).y AS y
),
cs_b AS (
    SELECT *
    FROM trajectory_decoded
)

SELECT *
FROM CS_KNN_Decoded(cs_a, cs_b, 21, 10);



--linestring distance results
WITH query_point AS (
    SELECT CS_CellAsPoint(1664470337539, 21) AS point
),
candidates AS (
    SELECT
        t.trajectory_id,
        t.geom,
        ST_Distance(t.geom, q.point) AS dist
    FROM trajectory_ls t
    CROSS JOIN query_point q
)

SELECT
    trajectory_id,
    MIN(dist) AS cell_dist
FROM candidates
GROUP BY trajectory_id
ORDER BY cell_dist
LIMIT 10;
