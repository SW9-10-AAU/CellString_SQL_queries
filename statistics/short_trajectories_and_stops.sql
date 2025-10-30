SELECT COUNT(*) as total_short_trajectories_ls
FROM prototype1.trajectory_ls
WHERE ST_NumPoints(geom) <= 3;

SELECT COUNT(*) as total_short_trajectories_cs
FROM prototype1.trajectory_cs
WHERE cardinality(cellstring) = 1;

SELECT COUNT(*) as total_empty_stops
FROM prototype1.stop_cs
WHERE cardinality(cellstring) = 0;