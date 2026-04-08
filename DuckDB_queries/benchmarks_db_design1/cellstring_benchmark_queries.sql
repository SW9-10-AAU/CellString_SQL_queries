--------------------------------------------------------------------------------------------------------------
-- Spatial Range
----------------------------------------------------------------------------------------------------------------
-- problem (we cant use our CS_intersects macro here, since it is not a table macro and we cant use it in
-- where clause. We give it two cellstrings(querytables) and it just return boolean, we will never be able to
-- use it to retrieve intersecting mmsi, trajectory_id, stops etc. only by using join here.

WITH selected_area AS (
    SELECT area_id, cell_z21
    FROM area_cs
    WHERE area_id = 3
)
SELECT DISTINCT
    t.mmsi,
    t.trajectory_id,
    NULL::INTEGER AS stop_id,
    a.area_id,
    'trajectory' AS source
FROM trajectory_cs t
JOIN selected_area a ON t.cell_z21 = a.cell_z21
UNION ALL
SELECT DISTINCT
    s.mmsi,
    NULL::INTEGER AS trajectory_id,
    s.stop_id,
    a.area_id,
    'stop' AS source
FROM stop_cs s
JOIN selected_area a ON s.cell_z21 = a.cell_z21;

--Temporal Range (don't give same result due to timezone mismatch of ls and cs (UTC time)
WITH p AS (
    -- 1 day (6.685 rows)
    SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-02 00:00:00.000' AS t_end
    -- 1 week (6.846 rows)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-08 00:00:00.000' AS t_end
    -- 1 month (6.846 rows) (same only one week data)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2026-01-01 00:00:00.000' AS t_end
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, 'trajectory' AS source
FROM trajectory_cs t, p
WHERE t.ts BETWEEN p.t_start AND p.t_end
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, 'stop' AS source
FROM stop_cs s, p
WHERE s.ts_start <= p.t_end
  AND s.ts_end >= p.t_start;


--Spatio-temporal Range
WITH p AS (
    -- 1 day: area_id 1 = (14 rows), area_id 2 = (65 rows), area_id 3 = (118 rows)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-02 00:00:00.000' AS t_end
    -- 1 week: area_id 1 = (17 rows), area_id 2 = (72 rows), area_id 3 = (123 rows)
    SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-08 00:00:00.000' AS t_end
    -- 1 month: area_id 1 = (17 rows), area_id 2 = (72 rows), area_id 3 = (123 rows)
    --SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2026-01-01 00:00:00.000' AS t_end
),
selected_area AS (
    SELECT area_id, cell_z21
    FROM area_cs
    WHERE area_id = 3
)
SELECT DISTINCT t.mmsi, t.trajectory_id, NULL::INTEGER AS stop_id, a.area_id, 'trajectory' AS source
FROM trajectory_cs t
JOIN selected_area a ON t.cell_z21 = a.cell_z21
JOIN p ON t.ts BETWEEN p.t_start AND p.t_end
UNION ALL
SELECT DISTINCT s.mmsi, NULL::INTEGER AS trajectory_id, s.stop_id, a.area_id, 'stop' AS source
FROM stop_cs s
JOIN selected_area a ON s.cell_z21 = a.cell_z21
JOIN p ON s.ts_start <= p.t_end AND s.ts_end >= p.t_start;

--Spatio-temporal Join (“ID Temporal”)

--Via Query (Spatial Join)

-- CoverageByMMSI




--check timezone match queries

--check number of each in temporal range 1 day
SELECT 'trajectory_ls' AS table_name, COUNT(DISTINCT trajectory_id) AS total_ids
FROM trajectory_ls
WHERE ts_start <= TIMESTAMP '2025-12-02 00:00:00.000' AND ts_end >= TIMESTAMP '2025-12-01 00:00:00.000'

UNION ALL

SELECT 'trajectory_cs' AS table_name, COUNT(DISTINCT trajectory_id) AS total_ids
FROM trajectory_cs
WHERE ts BETWEEN TIMESTAMP '2025-12-01 00:00:00.000' AND TIMESTAMP '2025-12-02 00:00:00.000'

UNION ALL

-- Note: Your previous scripts called this 'stop_poly', I used 'stop_ls' here based on your prompt, adjust if needed
SELECT 'stop_poly' AS table_name, COUNT(DISTINCT stop_id) AS total_ids
FROM stop_poly
WHERE ts_start <= TIMESTAMP '2025-12-02 00:00:00.000' AND ts_end >= TIMESTAMP '2025-12-01 00:00:00.000'

UNION ALL

SELECT 'stop_cs' AS table_name, COUNT(DISTINCT stop_id) AS total_ids
FROM stop_cs
WHERE ts_start <= TIMESTAMP '2025-12-02 00:00:00.000' AND ts_end >= TIMESTAMP '2025-12-01 00:00:00.000';

-- Check the stop_ids that are in stop_poly but not in stop_cs for the 1 day temporal range, and compare their timestamps
WITH p AS (
    SELECT TIMESTAMP '2025-12-01 00:00:00.000' AS t_start, TIMESTAMP '2025-12-02 00:00:00.000' AS t_end
),
poly_1day AS (
    SELECT DISTINCT stop_id FROM stop_poly, p WHERE ts_start <= p.t_end AND ts_end >= p.t_start
),
cs_1day AS (
    SELECT DISTINCT stop_id FROM stop_cs, p WHERE ts_start <= p.t_end AND ts_end >= p.t_start
),
-- Grab the 52 IDs that caused the discrepancy
missing_ids AS (
    SELECT stop_id FROM poly_1day
    EXCEPT
    SELECT stop_id FROM cs_1day
)

-- Compare the timestamps side-by-side
SELECT
    m.stop_id,
    sp.ts_start AS poly_start,
    sp.ts_end   AS poly_end,
    sc.ts_start AS cs_start,
    sc.ts_end   AS cs_end
FROM missing_ids m
JOIN stop_poly sp ON m.stop_id = sp.stop_id
-- We use DISTINCT on stop_cs because it has multiple rows (cells) per stop
JOIN (SELECT DISTINCT stop_id, ts_start, ts_end FROM stop_cs) sc ON m.stop_id = sc.stop_id
LIMIT 100;