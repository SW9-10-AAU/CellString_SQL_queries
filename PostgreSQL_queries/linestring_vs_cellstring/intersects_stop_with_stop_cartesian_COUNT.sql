-- Stop intersects with stop, cartesian product (count number of stops intersecting each stop)

--- ST_ version (0.8s) ---
SELECT
    stopA.stop_id,
    COUNT(stopB.stop_id) AS intersect_count
FROM
    prototype2.stop_poly AS stopA,
    prototype2.stop_poly AS stopB
WHERE stopA.stop_id <> stopB.stop_id
    AND stopA.mmsi <> stopB.mmsi
    AND ST_Intersects(stopA.geom, stopB.geom)
GROUP BY stopA.stop_id
ORDER BY intersect_count DESC;

--- CST_ version (5s) ---
SELECT
    stopA.stop_id,
    COUNT(stopB.stop_id) AS intersect_count
FROM
    prototype2.stop_cs AS stopA,
    prototype2.stop_cs AS stopB
WHERE stopA.stop_id <> stopB.stop_id
    AND stopA.mmsi <> stopB.mmsi
    AND CST_Intersects(stopA.cellstring_z21, stopB.cellstring_z21)
GROUP BY stopA.stop_id
ORDER BY intersect_count DESC;