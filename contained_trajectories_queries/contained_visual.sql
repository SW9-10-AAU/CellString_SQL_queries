-- ==========================================================
-- Visualize LineString containment with Supercover CellString
-- ==========================================================
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom AS original_trajectory,

    -- Decoded CellString as polygons at different zoom levels
    CST_AsMultiPolygon(cs.cellstring_z13, 13) AS cells_z13,
    CST_AsMultiPolygon(cs.cellstring_z17, 17) AS cells_z17,
    CST_AsMultiPolygon(cs.cellstring_z21, 21) AS cells_z21,

    -- Containment check (TRUE = contained, FALSE = violation)
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z13, 13), ls.geom) AS z13_contained,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z17, 17), ls.geom) AS z17_contained,
    ST_Contains(CST_AsMultiPolygon(cs.cellstring_z21, 21), ls.geom) AS z21_contained,

    -- Parts of trajectory NOT covered (for visualization of violations)
    ST_Difference(ls.geom, CST_AsMultiPolygon(cs.cellstring_z13, 13)) AS z13_uncovered,
    ST_Difference(ls.geom, CST_AsMultiPolygon(cs.cellstring_z17, 17)) AS z17_uncovered,
    ST_Difference(ls.geom, CST_AsMultiPolygon(cs.cellstring_z21, 21)) AS z21_uncovered

FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_contained_supercover_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id = 656;

-- on border example
--13
--LINESTRING (13.021545410156252 55.63551712036133, 13.02154541015625 55.63551712036133)