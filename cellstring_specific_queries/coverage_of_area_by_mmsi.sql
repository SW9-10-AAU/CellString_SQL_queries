-- Coverage of area (%) by mmsi

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
        prototype2.trajectory_cs AS traj,
        area
    WHERE
        CST_Intersects(traj.cellstring_z17, area.cellstring_z17)
),
mmsi_union AS (
    SELECT
        mmsi,
        CST_Union_Agg(covered_cells) AS union_cells,
        cardinality(CST_Union_Agg(covered_cells)) AS cell_count
    FROM traj_cover
    GROUP BY mmsi
)
SELECT
    mmsi,
    ROUND((cell_count::numeric / cardinality(area.cellstring_z17)) * 100, 2) AS coverage_percent
FROM mmsi_union, area
ORDER BY coverage_percent DESC;