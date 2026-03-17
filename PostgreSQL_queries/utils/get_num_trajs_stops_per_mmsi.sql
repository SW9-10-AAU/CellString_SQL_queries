-- Num trajectories per mmsi
SELECT
    mmsi,
    COUNT(*) AS trajectory_count
FROM prototype2.trajectory_ls
GROUP BY mmsi
ORDER BY trajectory_count DESC;

-- Num stops per mmsi
SELECT
    mmsi,
    COUNT(*) AS stop_count
FROM prototype2.stop_poly
GROUP BY mmsi
ORDER BY stop_count DESC;


-- Combined: Num trajectories and stops per mmsi
SELECT
    COALESCE(t.mmsi, s.mmsi) AS mmsi,
    COALESCE(t.trajectory_count, 0) AS trajectory_count,
    COALESCE(s.stop_count, 0) AS stop_count
FROM (
    SELECT mmsi, COUNT(*) AS trajectory_count
    FROM prototype2.trajectory_ls
    GROUP BY mmsi
) t
FULL OUTER JOIN (
    SELECT mmsi, COUNT(*) AS stop_count
    FROM prototype2.stop_poly
    GROUP BY mmsi
) s
ON t.mmsi = s.mmsi
ORDER BY trajectory_count DESC, stop_count DESC;