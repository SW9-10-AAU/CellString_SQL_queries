SELECT
    traj_ls.trajectory_id,
    ST_NumPoints(traj_ls.geom) AS num_points,
    ST_Length(ST_Transform(traj_ls.geom, 3857)) AS traj_length,
    cardinality(traj_cs.cellstring_z21) AS num_cells,
    CASE
        WHEN cardinality(traj_cs.cellstring_z21) > 0
        THEN ROUND(
            cardinality(traj_cs.cellstring_z21)::NUMERIC / ST_NumPoints(traj_ls.geom),
            2
        )
        ELSE NULL
    END AS points_cells_ratio
FROM prototype2.trajectory_ls AS traj_ls
JOIN prototype2.trajectory_cs AS traj_cs
    ON traj_ls.trajectory_id = traj_cs.trajectory_id
WHERE ST_NumPoints(traj_ls.geom) > 1000
ORDER BY points_cells_ratio DESC;

SELECT
    traj_ls.trajectory_id,
    ST_NumPoints(traj_ls.geom) AS num_points,
    ST_Length(ST_Transform(traj_ls.geom, 3857)) AS traj_length,
    cardinality(traj_cs.cellstring_z21) AS num_cells,
    CASE
        WHEN cardinality(traj_cs.cellstring_z21) > 0
        THEN ROUND(
            cardinality(traj_cs.cellstring_z21)::NUMERIC / ST_NumPoints(traj_ls.geom),
            2
        )
        ELSE NULL
    END AS points_cells_ratio
FROM prototype1.trajectory_ls AS traj_ls
JOIN prototype2.trajectory_cs AS traj_cs
    ON traj_ls.trajectory_id = traj_cs.trajectory_id
--WHERE ST_NumPoints(traj_ls.geom) > 1000
ORDER BY points_cells_ratio DESC;
