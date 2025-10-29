-- Coverage of area (%) by mmsi

WITH area AS (
    SELECT cellstring
    FROM benchmark.area_cs
    WHERE area_id = 2
),
traj_cover AS (
    SELECT
        traj.mmsi,
        CST_Intersection(traj.cellstring, area.cellstring) AS covered_cells
    FROM
        prototype1.trajectory_cs AS traj,
        area
    WHERE
        CST_Intersects(traj.cellstring, area.cellstring)
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
    ROUND((cell_count::numeric / cardinality(area.cellstring)) * 100, 2) AS coverage_percent
FROM mmsi_union, area
ORDER BY coverage_percent DESC;