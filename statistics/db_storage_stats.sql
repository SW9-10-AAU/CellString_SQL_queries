    --storage points
SELECT
    pg_size_pretty(pg_total_relation_size('prototype1.points')) AS pt1_points;



SELECT
    --storage prototype 1
    pg_size_pretty(pg_total_relation_size('prototype1.trajectory_cs')) AS pt1_cellstring_traj_size,
    pg_size_pretty(pg_relation_size('prototype1.trajectory_cs')) AS pt1_cellstring_traj_size_without_index,
    pg_size_pretty(pg_indexes_size('prototype1.trajectory_cs')) AS pt1_index_size,
    pg_size_pretty(pg_relation_size('prototype1.trajectory_cellstring_gin_idx')) AS pt1_gin_index_size,
    pg_size_pretty(pg_total_relation_size('prototype1.trajectory_ls')) AS pt1_linestring_traj_size,
    pg_size_pretty(pg_total_relation_size('prototype1.stop_cs')) AS pt1_cellstring_stop_size,
    pg_size_pretty(pg_total_relation_size('prototype1.stop_poly')) AS pt1_linestring_stop_size;



SELECT
    --storage prototype 2 (with zooms)
    pg_size_pretty(pg_total_relation_size('prototype2.trajectory_cs')) AS pt2_cellstring_traj_size,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cs')) AS pt2_cellstring_traj_size_without_index,
    pg_size_pretty(pg_indexes_size('prototype2.trajectory_cs')) AS pt2_index_size,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cellstring_z13_gin_idx')) AS pt2_gin_index_size_z13,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cellstring_z17_gin_idx')) AS pt2_gin_index_size_z17,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cellstring_z21_gin_idx')) AS pt2_gin_index_size_z21;
