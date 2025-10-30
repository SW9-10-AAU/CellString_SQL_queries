-- Find the amount small trajectories (2 points) contained in another trajectory

-- CellString version (7s)
SELECT
    traj_a.mmsi,
    traj_a.trajectory_id,
    COUNT(DISTINCT traj_b.trajectory_id) as duplicate_count
FROM
    prototype1.trajectory_cs AS traj_a
JOIN prototype1.trajectory_cs AS traj_b
    ON traj_a.mmsi = traj_b.mmsi
    AND traj_a.trajectory_id <> traj_b.trajectory_id
WHERE cardinality(traj_b.cellstring) < 3
    AND CST_Contains(traj_a.cellstring, traj_b.cellstring)
GROUP BY traj_a.trajectory_id
ORDER BY duplicate_count DESC;


-- LineString version (2m 9s)
-- mmsis: [219449000, 219019218, 219019219, 210912000, 219019218, 219019218, 219023786, 219186000, 219670000, 219186000]
-- trajids: [76091, 44554, 31617, 1787, 40325, 41882, 36572, 72472, 77847, 70228]
SELECT
    traj_a.mmsi,
    traj_a.trajectory_id,
    COUNT(DISTINCT traj_b.trajectory_id) as duplicate_count
FROM
    prototype1.trajectory_ls AS traj_a
JOIN prototype1.trajectory_ls AS traj_b
    ON traj_a.mmsi = traj_b.mmsi
    AND traj_a.trajectory_id <> traj_b.trajectory_id
WHERE ST_NumPoints(traj_b.geom) < 3
    AND ST_Contains(traj_a.geom, traj_b.geom)
GROUP BY traj_a.trajectory_id
ORDER BY duplicate_count DESC;