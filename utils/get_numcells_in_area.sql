SELECT
    area_id,
    name,
    cardinality(cellstring) as num_cells
FROM benchmark.area_cs
ORDER BY num_cells DESC;