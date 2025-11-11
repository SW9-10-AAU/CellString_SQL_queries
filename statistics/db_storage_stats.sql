SELECT
    --storage size
    pg_size_pretty(pg_total_relation_size('prototype2.trajectory_cs')) AS cellstring_traj_size,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cs')) AS cellstring_traj_size_without_index,
    pg_size_pretty(pg_indexes_size('prototype2.trajectory_cs')) AS index_size,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cellstring_gin_idx')) AS gin_index_size,
    pg_size_pretty(pg_total_relation_size('prototype2.trajectory_ls')) AS linestring_traj_size,
    pg_size_pretty(pg_total_relation_size('prototype2.stop_cs')) AS cellstring_stop_size,
    pg_size_pretty(pg_total_relation_size('prototype2.stop_poly')) AS linestring_stop_size,
    pg_size_pretty(pg_total_relation_size('prototype1.points')) AS points;