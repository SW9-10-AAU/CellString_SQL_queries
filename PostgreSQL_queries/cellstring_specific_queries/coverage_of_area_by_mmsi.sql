-- Coverage of area (%) by mmsi
SELECT *
FROM CST_Coverage_ByMMSI(
  'prototype2.trajectory_supercover_cs',
  13,
  (SELECT cellstring_z13 FROM benchmark.area_cs WHERE area_id = 26)
);

SELECT *
FROM cst_tilexy(110987570647260, 21);

SELECT *
FROM cst_CellAsPoint(110987570647260,21);


-- Alternatively, using the following explicit SQL:
-- Hals-Egense (0.8s)
-- Helsingør-Helsingborg (23s)
-- Læsø (????)
EXPLAIN ANALYZE
WITH area AS (
    SELECT cellstring_z13
    FROM benchmark.area_cs
    WHERE area_id = 3
),
traj_cover AS (
    SELECT
        traj.mmsi,
        CST_Intersection(traj.cellstring_z13, area.cellstring_z13) AS covered_cells
    FROM
        prototype2.trajectory_supercover_cs AS traj,
        area
    WHERE
        CST_Intersects(traj.cellstring_z13, area.cellstring_z13)
),
mmsi_union AS (
    SELECT
        mmsi,
        CST_Union_Agg(covered_cells) AS union_cells
    FROM traj_cover
    GROUP BY mmsi
)
SELECT
    mmsi,
    union_cells,
    CST_Coverage(union_cells, area.cellstring_z13) AS coverage_percent
FROM mmsi_union, area
ORDER BY coverage_percent DESC;


WITH area AS (
    SELECT
        cellstring_z13 AS cellstring,
        3::int AS area_id
    FROM benchmark.area_cs
    WHERE area_id = 3
)
SELECT
    area.area_id,
    coverage.mmsi,
    coverage.coverage_percent
FROM area
CROSS JOIN LATERAL CST_Coverage_ByMMSI(
    'prototype2.trajectory_supercover_cs'::regclass,
    13,
    area.cellstring
) AS coverage
ORDER BY coverage.coverage_percent DESC;