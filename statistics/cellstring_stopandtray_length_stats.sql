-- Trajectory lengths
SELECT
    ROUND(AVG(COALESCE(array_length(cellstring, 1), 0)), 1) AS avg_cellstring_length,
    MIN(COALESCE(array_length(cellstring, 1), 0))           AS min_cellstring_length,
    MAX(COALESCE(array_length(cellstring, 1), 0))           AS max_cellstring_length
FROM prototype1.trajectory_cs;

-- Stop lengths
SELECT
    ROUND(AVG(COALESCE(array_length(cellstring, 1), 0)), 1) AS avg_cellstring_length,
    MIN(COALESCE(array_length(cellstring, 1), 0))           AS min_cellstring_length,
    MAX(COALESCE(array_length(cellstring, 1), 0))           AS max_cellstring_length
FROM prototype1.stop_cs;

--traj_id of longest cell_traj
SELECT trajectory_id,
       array_length(cellstring, 1) AS cellstring_length
FROM prototype1.trajectory_cs
WHERE array_length(cellstring, 1) = (
    SELECT MAX(array_length(cellstring, 1))
    FROM prototype1.trajectory_cs
);


--stop_id of biggest cell_stop
SELECT stop_id,
       array_length(cellstring, 1) AS cellstring_length
FROM prototype1.stop_cs
WHERE array_length(cellstring, 1) = (
    SELECT MAX(array_length(cellstring, 1))
    FROM prototype1.stop_cs
);