-- Trajectory lengths
SELECT
    ROUND(AVG(arr_len), 1)                   AS avg_length,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY arr_len) AS median_length,
    MIN(arr_len)                             AS min_length,
    MAX(arr_len)                             AS max_length
FROM (
    SELECT COALESCE(array_length(cellstring_z21, 1), 0) AS arr_len
    FROM prototype2.trajectory_cs
--     FROM prototype2.trajectory_supercover_cs
) t;

-- Stop lengths
SELECT
    ROUND(AVG(arr_len), 1)                   AS avg_length,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY arr_len) AS median_length,
    MIN(arr_len)                             AS min_length,
    MAX(arr_len)                             AS max_length
FROM (
    SELECT COALESCE(array_length(cellstring_z21, 1), 0) AS arr_len
    FROM prototype2.stop_cs
) t;


--traj_id of longest cell_traj
SELECT trajectory_id,
       array_length(cellstring_z21, 1) AS cellstring_length
FROM prototype2.trajectory_cs
WHERE array_length(cellstring_z21, 1) = (
    SELECT MAX(array_length(cellstring_z21, 1))
    FROM prototype2.trajectory_cs
);


--stop_id of biggest cell_stop
SELECT stop_id,
       array_length(cellstring_z21, 1) AS cellstring_length
FROM prototype2.stop_cs
WHERE array_length(cellstring_z21, 1) = (
    SELECT MAX(array_length(cellstring_z21, 1))
    FROM prototype2.stop_cs
);