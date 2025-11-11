-- Stop intersects with stop, cartesian product (simple query)

--- ST_ version (0.6s) ---
SELECT
    stopA.stop_id,
    stopB.stop_id
FROM
    prototype2.stop_poly AS stopA,
    prototype2.stop_poly AS stopB
WHERE stopA.stop_id <> stopB.stop_id
    AND stopA.mmsi <> stopB.mmsi
    AND ST_Intersects(stopA.geom, stopB.geom);

--- CST_ version (0.8s) ---
SELECT
    stopA.stop_id,
    stopB.stop_id
FROM
    prototype2.stop_cs AS stopA,
    prototype2.stop_cs AS stopB
WHERE stopA.stop_id <> stopB.stop_id
    AND stopA.mmsi <> stopB.mmsi
    AND CST_Intersects(stopA.cellstring_z21, stopB.cellstring_z21);
