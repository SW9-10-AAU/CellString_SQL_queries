-- Stop intersects with stop, cartesian product (percentage overlap)

--- ST_ version (1.4s) ---
SELECT
    stopA.stop_id,
    stopB.stop_id,
    ROUND(
        (ST_Area(ST_Intersection(stopA.geom, stopB.geom)) / ST_Area(stopA.geom))::numeric * 100,
        2
    ) AS overlap_percent
FROM
    prototype2.stop_poly AS stopA,
    prototype2.stop_poly AS stopB
WHERE
    stopA.stop_id <> stopB.stop_id
    AND stopA.mmsi <> stopB.mmsi
    AND ST_Intersects(stopA.geom, stopB.geom)
ORDER BY overlap_percent DESC;

--- CST_ version (5s) ---
SELECT
    stopA.stop_id,
    stopB.stop_id,
    ROUND(
        (cardinality(CST_Intersection(stopA.cellstring, stopB.cellstring))::numeric
         / cardinality(stopA.cellstring)) * 100,
        2
    ) AS overlap_percent
FROM
    prototype2.stop_cs AS stopA,
    prototype2.stop_cs AS stopB
WHERE
    stopA.stop_id <> stopB.stop_id
    AND stopA.mmsi <> stopB.mmsi
    AND CST_Intersects(stopA.cellstring, stopB.cellstring)
ORDER BY overlap_percent DESC;