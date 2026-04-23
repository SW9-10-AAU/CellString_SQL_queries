SELECT COUNT(*) as total_short_trajectories_ls
FROM prototype2.trajectory_ls
WHERE ST_NumPoints(geom) <= 3;

SELECT COUNT(*) as total_short_trajectories_cs
FROM prototype2.trajectory_cs
WHERE cardinality(cellstring) = 1;

SELECT COUNT(*) as total_empty_stops
FROM prototype2.stop_cs
WHERE cardinality(cellstring) = 0;