-- Areas
SELECT
    area_id,
    name,
    cardinality(cellstring_z21) as num_cells_z21,
    cardinality(cellstring_z17) as num_cells_z17,
    cardinality(cellstring_z13) as num_cells_z13
FROM benchmark.area_cs
ORDER BY num_cells_z21 DESC;

-- Crossings
SELECT
    crossing_id,
    name,
    cardinality(cellstring_z21) as num_cells_z21,
    cardinality(cellstring_z17) as num_cells_z17,
    cardinality(cellstring_z13) as num_cells_z13
FROM benchmark.crossing_cs
ORDER BY num_cells_z21 DESC;