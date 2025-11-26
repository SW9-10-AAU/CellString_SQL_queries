-- Coverage of area (%) by trajectory_id

SELECT
    traj.mmsi,
    traj.trajectory_id,
    CST_Coverage(traj.cellstring_z17, area.cellstring_z17) AS coverage_percent
FROM
    prototype2.trajectory_cs AS traj,
    benchmark.area_cs as area
WHERE
    area.area_id = 3
    AND CST_Intersects(traj.cellstring_z17, area.cellstring_z17)
ORDER BY coverage_percent DESC;
