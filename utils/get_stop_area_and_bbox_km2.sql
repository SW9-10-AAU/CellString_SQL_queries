SELECT
    mmsi,
    stop_id,
    geom,
    ST_AREA(ST_TRANSFORM(geom, 3857)) as stop_area_m2,
    ST_AREA(ST_TRANSFORM(geom, 3857)) / 1e6 as stop_area_km2
FROM prototype2.stop_poly
ORDER BY ST_AREA(geom) DESC;

SELECT
    mmsi,
    stop_id,
    ST_AREA(ST_TRANSFORM(ST_Envelope(geom), 3857)) as stop_bbox_area_m2,
    ST_AREA(ST_TRANSFORM(ST_Envelope(geom), 3857)) / 1e6 as stop_bbox_area_km2
FROM prototype2.stop_poly
ORDER BY ST_AREA(ST_Envelope(geom)) DESC;