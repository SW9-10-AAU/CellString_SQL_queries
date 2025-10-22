SELECT
    --storage size
    pg_size_pretty(pg_total_relation_size('prototype1.trajectory_cs')) AS cellstring_traj_size,
    pg_size_pretty(pg_total_relation_size('prototype1.trajectory_ls')) AS linestring_traj_size,
    pg_size_pretty(pg_total_relation_size('prototype1.stop_cs')) AS cellstring_stop_size,
    pg_size_pretty(pg_total_relation_size('prototype1.stop_poly')) AS linestring_stop_size,
    pg_size_pretty(pg_total_relation_size('prototype1.points')) AS points;