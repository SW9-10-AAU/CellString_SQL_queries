-- Using an example trajectory (with many short trajectories contained in the long trajectory)
-- Trajectory id: 76091

-- Long trajectory
SELECT *
FROM prototype2.trajectory_ls
WHERE trajectory_id = 76091;


-- Short trajectories contained in long trajectory
SELECT
    traj_a.mmsi,
    traj_a.trajectory_id,
    traj_b.*
FROM
    prototype2.trajectory_ls AS traj_a,
    prototype2.trajectory_ls AS traj_b
WHERE
    traj_a.trajectory_id = 76091
    AND ST_NumPoints(traj_b.geom) = 2
    AND traj_a.trajectory_id <> traj_b.trajectory_id
    AND traj_a.mmsi = traj_b.mmsi
    AND ST_Contains(traj_a.geom, traj_b.geom);



-- Long + contained short trajectories in one query
SELECT
    traj_b.mmsi,
    traj_b.trajectory_id,
    traj_b.geom
FROM
    prototype2.trajectory_ls AS traj_a,
    prototype2.trajectory_ls AS traj_b
WHERE
    traj_a.trajectory_id = 76091
    AND traj_a.trajectory_id <> traj_b.trajectory_id
    AND traj_a.mmsi = traj_b.mmsi
    AND ST_NumPoints(traj_b.geom) = 2
    AND ST_Contains(traj_a.geom, traj_b.geom)

UNION ALL

SELECT
    traj_a.mmsi,
    traj_a.trajectory_id,
    traj_a.geom
FROM
    prototype2.trajectory_ls AS traj_a
WHERE
    traj_a.trajectory_id = 76091;