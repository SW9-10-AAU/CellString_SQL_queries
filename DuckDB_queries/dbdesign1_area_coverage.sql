LOAD spatial;

SELECT * FROM p10.trajectory_ls WHERE trajectory_id = 1;


-- Visualise area (Kattegat)
SELECT area_id, name, '54,526,908 z21 cells' as num_cells, ST_AsText(geom) as geom
FROM jgl_etl_performance_fix.area_poly
WHERE area_id = 4;

SELECT  area_id,
        name,
        ST_AsText(geom) as geom,
        ST_AsText(fast_CST_AsPolygon('jgl_etl_performance_fix.area_cs', 'area_id', 2)) AS cellstring_geom
FROM jgl_etl_performance_fix.area_poly
WHERE area_id = 2;

-- Area coverage
WITH query_area AS (SELECT cell_z21,
                      FROM jgl_etl_performance_fix.area_cs
                      WHERE area_id = 2)
SELECT DISTINCT t.trajectory_id,
                t.cell_z21 as overlap_cells,
                ST_AsText(fast_tile_to_geom(t.cell_z21, 21)) AS geom
FROM jgl_etl_performance_fix.trajectory_cs t
         JOIN query_area tc
              ON t.cell_z21 = tc.cell_z21
WHERE t.mmsi = 211757470;


WITH query_area AS (
    SELECT cell_z21
    FROM jgl_etl_performance_fix.area_cs
    WHERE area_id = 2
),
combined_cells AS (
    -- Trajectory cells
    SELECT
        trajectory_id AS id,
        'trajectory' AS source_type,
        cell_z21
    FROM jgl_etl_performance_fix.trajectory_cs
    WHERE mmsi = 211757470

    UNION

    -- Stop cells
    SELECT
        stop_id AS id,
        'stop' AS source_type,
        cell_z21
    FROM jgl_etl_performance_fix.stop_cs
    WHERE mmsi = 211757470
)
SELECT DISTINCT
    c.id,
    c.source_type,
    c.cell_z21 AS overlap_cell,
    ST_AsText(fast_tile_to_geom(c.cell_z21, 21)) AS geom
FROM combined_cells c
JOIN query_area tc
    ON c.cell_z21 = tc.cell_z21;


WITH area_cells AS (
    -- Total footprint of the target area
    SELECT cell_z21
    FROM jgl_etl_performance_fix.area_cs
    WHERE area_id = 2
),
vessel_cells AS (
    -- Distinct spatial footprint of the vessel (trajectories + stops)
    SELECT cell_z21
    FROM jgl_etl_performance_fix.trajectory_cs
    WHERE mmsi = 211757470
    UNION -- UNION deduplicates cells occurring in both tables
    SELECT cell_z21
    FROM jgl_etl_performance_fix.stop_cs
    WHERE mmsi = 211757470
),
intersection_count AS (
    -- Count how many vessel cells fall within the area
    SELECT COUNT(vc.cell_z21) AS intersecting_cells
    FROM vessel_cells vc
    INNER JOIN area_cells ac ON vc.cell_z21 = ac.cell_z21
),
total_area_count AS (
    -- Total capacity of the area
    SELECT COUNT(*) AS total_cells
    FROM area_cells
)
SELECT
    'Hirtshals Havn' as area_name,
    211757470 as mmsi,
    i.intersecting_cells,
    t.total_cells,
    ROUND(
        (i.intersecting_cells::numeric / NULLIF(t.total_cells, 0)) * 100,
        2
    ) AS coverage_percentage
FROM intersection_count i, total_area_count t;


SELECT * FROM CST_CoverageByMMSI(
    jgl_etl_performance_fix.area_cs,
    4,
    jgl_etl_performance_fix.trajectory_cs,
    jgl_etl_performance_fix.stop_cs
);

CREATE OR REPLACE MACRO CST_CoverageByMMSI(area_table, target_area_id, traj_table, stop_table) AS TABLE (
    WITH area_cells AS (
        SELECT
            cell_z21,
            COUNT(*) OVER() AS total_cells_in_area
        FROM query_table(area_table)
        WHERE area_id = target_area_id
    ),
    vessel_footprint AS (
        SELECT mmsi, cell_z21 FROM query_table(traj_table)
        UNION
        SELECT mmsi, cell_z21 FROM query_table(stop_table)
    ),
    intersecting_cells AS (
        SELECT
            v.mmsi,
            v.cell_z21,
            a.total_cells_in_area
        FROM vessel_footprint v
        INNER JOIN area_cells a ON v.cell_z21 = a.cell_z21
    )
    SELECT
        mmsi,
        COUNT(cell_z21) AS intersecting_cells,
        MAX(total_cells_in_area) AS total_area_cells,
        ROUND(
            (COUNT(cell_z21)::DOUBLE / NULLIF(MAX(total_cells_in_area), 0)) * 100,
            4
        ) AS coverage_percentage
    FROM intersecting_cells
    GROUP BY mmsi
    ORDER BY coverage_percentage DESC
);