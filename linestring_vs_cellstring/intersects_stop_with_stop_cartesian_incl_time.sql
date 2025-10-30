-- Stop intersects with stop, cartesian product (including time dimension)

--- ST_ version (0.85s) ---
SELECT
    stopA.stop_id,
    stopB.stop_id,
    GREATEST(stopA.ts_start, stopB.ts_start) AS overlap_start,
    LEAST(stopA.ts_end, stopB.ts_end) AS overlap_end,
    LEAST(stopA.ts_end, stopB.ts_end)
      - GREATEST(stopA.ts_start, stopB.ts_start) AS overlap_duration
FROM
    prototype1.stop_poly AS stopA,
    prototype1.stop_poly AS stopB
WHERE stopA.stop_id <> stopB.stop_id
  AND stopA.mmsi <> stopB.mmsi
  AND stopA.ts_start < stopB.ts_end
  AND stopB.ts_start < stopA.ts_end
  AND ST_Intersects(stopA.geom, stopB.geom)
ORDER BY overlap_duration DESC;

--- CST_ version (5s) ---
SELECT
    stopA.stop_id,
    stopB.stop_id,
    GREATEST(stopA.ts_start, stopB.ts_start) AS overlap_start,
    LEAST(stopA.ts_end, stopB.ts_end) AS overlap_end,
    LEAST(stopA.ts_end, stopB.ts_end)
      - GREATEST(stopA.ts_start, stopB.ts_start) AS overlap_duration
FROM
    prototype1.stop_cs AS stopA,
    prototype1.stop_cs AS stopB
WHERE stopA.stop_id <> stopB.stop_id
  AND stopA.mmsi <> stopB.mmsi
  AND stopA.ts_start < stopB.ts_end
  AND stopB.ts_start < stopA.ts_end
  AND CST_Intersects(stopA.cellstring, stopB.cellstring)
ORDER BY overlap_duration DESC;
