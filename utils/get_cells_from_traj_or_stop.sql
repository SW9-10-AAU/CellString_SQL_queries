SELECT 
    traj_ls.trajectory_id,
    ST_NumPoints(traj_ls.geom) AS num_points,
    cardinality(traj_cs.cellstring) AS num_cells
FROM prototype1.trajectory_ls AS traj_ls
JOIN prototype1.trajectory_cs AS traj_cs 
    ON traj_ls.trajectory_id = traj_cs.trajectory_id
WHERE traj_ls.trajectory_id = 103078;
