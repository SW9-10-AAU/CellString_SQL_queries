-- Retrieve points from trajectory --
SELECT to_timestamp(ST_M(point.geom)) as point_time, point.*
FROM prototype1.points as point
JOIN prototype1.trajectory_ls as traj ON traj.mmsi = point.mmsi
WHERE traj.trajectory_id = 54
    AND ST_M(point.geom) BETWEEN
        EXTRACT(EPOCH FROM traj.ts_start)
        AND EXTRACT(EPOCH FROM traj.ts_end)
ORDER BY ST_M(point.geom);

-- Retrieve points from stop --
SELECT to_timestamp(ST_M(point.geom)) as point_time, point.*
FROM prototype1.points as point
JOIN prototype1.stop_poly as stop ON stop.mmsi = point.mmsi
WHERE stop.stop_id = 2267
    AND ST_M(point.geom) BETWEEN
        EXTRACT(EPOCH FROM stop.ts_start)
        AND EXTRACT(EPOCH FROM stop.ts_end)
ORDER BY ST_M(point.geom);