-- Areas
SELECT
    area_cs.area_id,
    area_cs.name,
    area_poly.geom,
--     CST_AsMultiPolygon(cellstring_z21, 21) as cellstring_z21,
--     CST_AsMultiPolygon(cellstring_z17, 17) as cellstring_z17,
    CST_AsMultiPolygon(cellstring_z13, 13) as cellstring_z13
FROM benchmark.area_cs as area_cs
JOIN benchmark.area_poly as area_poly on area_cs.area_id = area_poly.area_id
WHERE area_cs.area_id = 26;
-- WHERE area_cs.area_id NOT IN (1, 23); -- Excluding Læsø region (too large in z21)

-- Crossings
SELECT
    crossing_cs.crossing_id,
    crossing_cs.name,
    crossing_ls.geom,
    CST_AsMultiPolygon(cellstring_z21, 21) as cellstring_z21,
    CST_AsMultiPolygon(cellstring_z17, 17) as cellstring_z17,
    CST_AsMultiPolygon(cellstring_z13, 13) as cellstring_z13
FROM benchmark.crossing_cs as crossing_cs
JOIN benchmark.crossing_ls as crossing_ls on crossing_cs.crossing_id = crossing_ls.crossing_id;
