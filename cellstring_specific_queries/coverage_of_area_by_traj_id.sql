-- Coverage of area (%) by trajectory_id

SELECT
    traj.mmsi,
    traj.trajectory_id,
    ROUND(
        (cardinality(CST_Intersection(traj.cellstring, area.cellstring))::numeric
         / cardinality(area.cellstring)) * 100,
        2
    ) AS coverage_percent
FROM
    prototype1.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 3
    AND CST_Intersects(traj.cellstring, area.cellstring)
ORDER BY coverage_percent DESC;
