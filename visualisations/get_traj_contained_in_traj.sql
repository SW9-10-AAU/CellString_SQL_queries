SELECT
    traj_a.mmsi,
    traj_a.trajectory_id,
    traj_b.*
FROM
    prototype1.trajectory_ls AS traj_a,
    prototype1.trajectory_ls AS traj_b
WHERE
    traj_a.trajectory_id = 76091
    AND ST_NumPoints(traj_b.geom) = 2
    AND traj_a.trajectory_id <> traj_b.trajectory_id
    AND traj_a.mmsi = traj_b.mmsi
    AND ST_Contains(traj_a.geom, traj_b.geom);
