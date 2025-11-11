WITH filtered AS (
  SELECT trajectory_id, geom
  FROM prototype2.trajectory_ls
  WHERE ST_NumPoints(geom) BETWEEN 9950 AND 10050
)
SELECT DISTINCT a.trajectory_id, b.trajectory_id
FROM filtered a
JOIN filtered b
  ON a.trajectory_id < b.trajectory_id
  AND ST_Intersects(a.geom, b.geom);