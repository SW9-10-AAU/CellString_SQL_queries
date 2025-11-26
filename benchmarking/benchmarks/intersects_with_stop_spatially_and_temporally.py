from benchmarking.core import TimeBenchmark

ST_SQL = """
WITH ref AS (
    SELECT mmsi,
           stop_id,
           geom AS ref_geom,
           ts_start AS ref_start,
           ts_end   AS ref_end
    FROM prototype2.stop_poly
    WHERE stop_id = %s
)

-- 0. Reference stop (always returned)
SELECT
    'REFERENCE STOP' as type,
    r.mmsi,
    NULL::bigint AS trajectory_id,
    r.stop_id,
    NULL::double precision AS overlap_minutes
FROM ref r

UNION

-- 1. Trajectory matches
SELECT DISTINCT
    'INTERSECTING TRAJECTORY' as type,
    t.mmsi,
    t.trajectory_id,
    NULL::bigint AS stop_id,
    ROUND(EXTRACT(
        EPOCH FROM (
            LEAST(t.ts_end,   r.ref_end)
          - GREATEST(t.ts_start, r.ref_start)
        )
    ) / 60.0, 2) AS overlap_minutes
FROM ref r
JOIN prototype2.trajectory_ls t
  ON t.mmsi <> r.mmsi
 AND ST_Intersects(t.geom, r.ref_geom)
 AND t.ts_end   >= r.ref_start
 AND t.ts_start <= r.ref_end

UNION

-- 2. Stop matches
SELECT DISTINCT
    'INTERSECTING STOP' as type,
    s.mmsi,
    NULL::bigint AS trajectory_id,
    s.stop_id,
    ROUND(EXTRACT(
        EPOCH FROM (
            LEAST(s.ts_end,   r.ref_end)
          - GREATEST(s.ts_start, r.ref_start)
        )
    ) / 60.0, 2) AS overlap_minutes
FROM ref r
JOIN prototype2.stop_poly s
  ON s.mmsi <> r.mmsi
 AND ST_Intersects(s.geom, r.ref_geom)
 AND s.ts_end   >= r.ref_start
 AND s.ts_start <= r.ref_end;
"""

CST_SQL = """
WITH ref AS (
    SELECT mmsi,
           stop_id,
           cellstring_{zoom} as ref_cellstring,
           ts_start AS ref_start,
           ts_end   AS ref_end
    FROM prototype2.stop_cs
    WHERE stop_id = %s
)

-- 0. Reference stop (always returned)
SELECT
    'REFERENCE STOP' as type,
    r.mmsi,
    NULL::bigint AS trajectory_id,
    r.stop_id,
    NULL::double precision AS overlap_minutes
FROM ref r

UNION

-- 1. Trajectory matches
SELECT DISTINCT
    'INTERSECTING TRAJECTORY' as type,
    t.mmsi,
    t.trajectory_id,
    NULL::bigint AS stop_id,
    ROUND(EXTRACT(
        EPOCH FROM (
            LEAST(t.ts_end,   r.ref_end)
          - GREATEST(t.ts_start, r.ref_start)
        )
    ) / 60.0, 2) AS overlap_minutes
FROM ref r
JOIN prototype2.trajectory_supercover_cs t
  ON t.mmsi <> r.mmsi
 AND CST_Intersects(t.cellstring_{zoom}, r.ref_cellstring)
 AND t.ts_end   >= r.ref_start
 AND t.ts_start <= r.ref_end

UNION

-- 2. Stop matches
SELECT DISTINCT
    'INTERSECTING STOP' as type,
    s.mmsi,
    NULL::bigint AS trajectory_id,
    s.stop_id,
    ROUND(EXTRACT(
        EPOCH FROM (
            LEAST(s.ts_end,   r.ref_end)
          - GREATEST(s.ts_start, r.ref_start)
        )
    ) / 60.0, 2) AS overlap_minutes
FROM ref r
JOIN prototype2.stop_cs s
  ON s.mmsi <> r.mmsi
 AND CST_Intersects(s.cellstring_{zoom}, r.ref_cellstring)
 AND s.ts_end   >= r.ref_start
 AND s.ts_start <= r.ref_end;
"""

BENCHMARK = TimeBenchmark(
    name="Find trajectories and stops that intersect a given stop spatially and temporally",
    st_sql=ST_SQL,
    cst_sql=CST_SQL,
    with_stop_ids=True,
    zoom_levels=["z13", "z17", "z21"],
)

