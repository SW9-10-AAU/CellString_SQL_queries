--trajectory cellstring histogram without intervals
SELECT
    COALESCE(array_length(cellstring_z21, 1), 0) AS array_length,
    COUNT(*) AS count
FROM prototype2.trajectory_cs
GROUP BY array_length
ORDER BY array_length;

--stop cellstring histogram without intervals
SELECT
  CASE
    WHEN cellstring IS NULL OR array_length(cellstring_z21,1) IS NULL THEN 0
    ELSE array_length(cellstring_z21,1)
  END AS len,
  COUNT(*)
FROM prototype2.stop_cs
GROUP BY len
ORDER BY len;



--trajectory cellstring with intervals
WITH settings AS (
  SELECT 50 AS interval_size
)
SELECT
  floor(array_length(cellstring_z21,1) / s.interval_size) * s.interval_size AS interval_start,
  floor(array_length(cellstring_z21,1) / s.interval_size) * s.interval_size + s.interval_size - 1 AS interval_end,
  COUNT(*) AS count
FROM prototype2.trajectory_cs, settings s
WHERE cellstring_z21 IS NOT NULL
GROUP BY interval_start, interval_end
ORDER BY interval_start;


-- stop cellstring length with intervals
WITH settings AS (
  SELECT 1000 AS interval_size  --adjust size here
)
SELECT
  floor(array_length(cellstring_z21,1) / s.interval_size) * s.interval_size AS interval_start,
  floor(array_length(cellstring_z21,1) / s.interval_size) * s.interval_size + s.interval_size - 1 AS interval_end,
  COUNT(*) AS count
FROM prototype2.stop_cs, settings s
WHERE cellstring IS NOT NULL
GROUP BY interval_start, interval_end
ORDER BY interval_start;