-- Coverage of area (%) by trajectory_id

SELECT
    traj.mmsi,
    traj.trajectory_id,
    ROUND(
        (cardinality(CST_Intersection(traj.cellstring_z21, area.cellstring_z21))::numeric
         / cardinality(area.cellstring_z21)) * 100,
        2
    ) AS coverage_percent
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 3
    AND CST_Intersects(traj.cellstring_z21, area.cellstring_z21)
ORDER BY coverage_percent DESC;
