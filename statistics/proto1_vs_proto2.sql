-- Sum the number of cells as CARDINALITY(cellstring) per trajectory
WITH p1 AS (
  SELECT
    trajectory_id,
    SUM(COALESCE(CARDINALITY(cellstring), 0)) AS cell_count
  FROM prototype1.trajectory_cs
  GROUP BY trajectory_id
),
p2 AS (
  SELECT
    trajectory_id,
    SUM(COALESCE(CARDINALITY(cellstring), 0)) AS cell_count
  FROM prototype2.trajectory_cs
  GROUP BY trajectory_id
)
SELECT
  COALESCE(p1.trajectory_id, p2.trajectory_id) AS trajectory_id,
  COALESCE(p1.cell_count, 0) AS p1_cell_count,
  COALESCE(p2.cell_count, 0) AS p2_cell_count,
  COALESCE(p2.cell_count, 0) - COALESCE(p1.cell_count, 0) AS diff,
  CASE
    WHEN COALESCE(p1.cell_count, 0) = 0 THEN NULL
    ELSE ROUND(100.0 * (COALESCE(p2.cell_count, 0) - COALESCE(p1.cell_count, 0)) / p1.cell_count, 2)
  END AS pct_change_from_p1
FROM p1
FULL OUTER JOIN p2 USING (trajectory_id)
ORDER BY diff;
