-- Coverage of area (%) by mmsi

SELECT *
FROM CST_Coverage_ByMMSI(
  'prototype2.trajectory_supercover_cs',
  17,
  (SELECT cellstring_z17 FROM benchmark.area_cs WHERE area_id = 3)
);


-- Alternatively, using the following explicit SQL:
-- Hals-Egense (0.8s)
-- Helsingør-Helsingborg (23s)
-- Læsø (????)
WITH area AS (
    SELECT cellstring_z17
    FROM benchmark.area_cs
    WHERE area_id = 3
),
traj_cover AS (
    SELECT
        traj.mmsi,
        CST_Intersection(traj.cellstring_z17, area.cellstring_z17) AS covered_cells
    FROM
        prototype2.trajectory_supercover_cs AS traj,
        area
    WHERE
        CST_Intersects(traj.cellstring_z17, area.cellstring_z17)
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
    CST_Coverage(union_cells, area.cellstring_z17) AS coverage_percent
FROM mmsi_union, area
ORDER BY coverage_percent DESC;