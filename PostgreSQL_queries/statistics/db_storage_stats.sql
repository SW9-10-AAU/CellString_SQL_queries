SELECT
    --storage prototype 1
    pg_size_pretty(pg_total_relation_size('prototype1.trajectory_cs')) AS pt1_cellstring_traj_size,
    pg_size_pretty(pg_relation_size('prototype1.trajectory_cs')) AS pt1_cellstring_traj_size_without_index,
    pg_size_pretty(pg_indexes_size('prototype1.trajectory_cs')) AS pt1_index_size,
    pg_size_pretty(pg_relation_size('prototype1.trajectory_cellstring_gin_idx')) AS pt1_gin_index_size,
    pg_size_pretty(pg_total_relation_size('prototype1.trajectory_ls')) AS pt1_linestring_traj_size,
    pg_size_pretty(pg_total_relation_size('prototype1.stop_cs')) AS pt1_cellstring_stop_size,
    pg_size_pretty(pg_total_relation_size('prototype1.stop_poly')) AS pt1_linestring_stop_size;

--------------------------------Prototype 2 storage stats ----------------------------

--storage points prototype 2
SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.points')) AS pt2_points,
    pg_size_pretty(pg_table_size('prototype2.points')) AS pt2_linestring_traj_table_size,
    pg_size_pretty(pg_indexes_size('prototype2.points')) AS pt2_linestring_traj_index_size;

--storage linestring trajectory prototype 2
SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.trajectory_ls')) AS pt2_linestring_traj_totalsize,
    pg_size_pretty(pg_table_size('prototype2.trajectory_ls')) AS pt2_linestring_traj_table_size,
    pg_size_pretty(pg_indexes_size('prototype2.trajectory_ls')) AS pt2_linestring_traj_index_size;

--storage polygon stop prototype 2
SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.stop_poly')) AS pt2_polygon_stop_totalsize,
    pg_size_pretty(pg_table_size('prototype2.stop_poly')) AS pt2_polygon_stop_data_size,
    pg_size_pretty(pg_indexes_size('prototype2.stop_poly')) AS pt2_polygon_stop_index_size;

--storage cellstring trajectory prototype 2 (with zooms) - Bresenham
SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.trajectory_cs')) AS pt2_cellstring_bresenham_traj_totalsize,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cs')) AS pt2_cellstring_bresenham_traj_data_size,
    pg_size_pretty(pg_indexes_size('prototype2.trajectory_cs')) AS pt2_cellstring_bresenham_traj_index_size,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cellstring_z13_gin_idx')) AS pt2_bresenham_traj_gin_index_size_z13,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cellstring_z17_gin_idx')) AS pt2_bresenham_traj_gin_index_size_z17,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_cellstring_z21_gin_idx')) AS pt2_bresenham_traj_gin_index_size_z21;

--storage cellstring trajectory prototype 2 (with zooms) - Bresenham-supercover
SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.trajectory_supercover_cs')) AS pt2_cellstring_supercover_traj_totalsize,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_supercover_cs')) AS pt2_cellstring_supercover_traj_data_size,
    pg_size_pretty(pg_indexes_size('prototype2.trajectory_supercover_cs')) AS pt2_cellstring_supercover_traj_index_size,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_supercover_cs_z13_gin_idx')) AS pt2_supercover_traj_gin_index_size_z13,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_supercover_cs_z17_gin_idx')) AS pt2_supercover_traj_gin_index_size_z17,
    pg_size_pretty(pg_relation_size('prototype2.trajectory_supercover_cs_z21_gin_idx')) AS pt2_supercover_traj_gin_index_size_z21;

-- storage cellstring stop prototype 2 (with zooms)
SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.stop_cs')) AS pt2_cellstring_stop_totalsize,
    pg_size_pretty(pg_relation_size('prototype2.stop_cs')) AS pt2_cellstring_stop_data_size,
    pg_size_pretty(pg_indexes_size('prototype2.stop_cs')) AS pt2_cellstring_stop_index_size,
    pg_size_pretty(pg_relation_size('prototype2.stop_cellstring_z13_gin_idx')) AS pt2_cellstring_stop_gin_index_size_z13,
    pg_size_pretty(pg_relation_size('prototype2.stop_cellstring_z17_gin_idx')) AS pt2_cellstring_stop_gin_index_size_z17,
    pg_size_pretty(pg_relation_size('prototype2.stop_cellstring_z21_gin_idx')) AS pt2_cellstring_stop_gin_index_size_z21;

SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.trajectory_cs')) AS pt2_cellstring_bresenham_traj_totalsize,
    pg_size_pretty(pg_table_size('prototype2.trajectory_cs')) AS pt2_cellstring_bresenham_traj_table_size,
    pg_size_pretty(pg_indexes_size('prototype2.trajectory_cs')) AS pt2_cellstring_bresenham_traj_index_size

SELECT
    pg_size_pretty(pg_total_relation_size('prototype2.stop_cs')) AS pt2_cellstring_bresenham_traj_totalsize,
    pg_size_pretty(pg_table_size('prototype2.stop_cs')) AS pt2_cellstring_bresenham_traj_table_size,
    pg_size_pretty(pg_indexes_size('prototype2.stop_cs')) AS pt2_cellstring_bresenham_traj_index_size