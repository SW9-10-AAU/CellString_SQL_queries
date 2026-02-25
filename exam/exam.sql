-- Denmark EEZ
SELECT
    area_cs.name,
    area_poly.geom,
    CST_AsMultiPolygon(cellstring_z13, 13) as cellstring_z13,
    cardinality(cellstring_z13) as area_cardinality_z13
--     CST_AsMultiPolygon(cellstring_z17, 17) as cellstring_z17,
--     cardinality(cellstring_z17) as area_cardinality_z17
FROM benchmark.area_cs as area_cs
JOIN benchmark.area_poly as area_poly on area_cs.name = area_poly.name
WHERE area_cs.name = 'Denmark-EEZ-new';


-- CoverageBy of EEZ-simple
SELECT *
FROM CST_Coverage_ByMMSI(
  'prototype2.trajectory_supercover_cs',
  13,
  (SELECT cellstring_z13 FROM benchmark.area_cs WHERE name = 'Denmark-EEZ-new')
);


-- COVERAGE OF AREA (visualisation)
WITH
params AS (
    SELECT
        27::int     AS area_id,
        636018490::bigint AS mmsi,
        13::int    AS zoom
),
area_poly AS (
    SELECT ap.area_id, ap.geom
    FROM benchmark.area_poly ap
    JOIN params p ON p.area_id = ap.area_id
),
area_cs AS (
    SELECT
        p.area_id,
        p.zoom,
        CASE p.zoom
            WHEN 13 THEN ac.cellstring_z13
            WHEN 17 THEN ac.cellstring_z17
            WHEN 21 THEN ac.cellstring_z21
            ELSE NULL
        END AS area_cells
    FROM benchmark.area_cs ac
    JOIN params p ON p.area_id = ac.area_id
),
traj_cs AS (
    SELECT
        p.mmsi,
        p.zoom,
        CST_Union_Agg(
            CASE p.zoom
                WHEN 13 THEN tc.cellstring_z13
                WHEN 17 THEN tc.cellstring_z17
                WHEN 21 THEN tc.cellstring_z21
                ELSE NULL
            END
        ) AS traj_cells
    FROM prototype2.trajectory_cs tc
    JOIN params p ON tc.mmsi = p.mmsi
    GROUP BY p.mmsi, p.zoom
),
intersection_cs AS (
    SELECT
        a.zoom,
        CST_Intersection(t.traj_cells, a.area_cells) AS inter_cells
    FROM area_cs a
    JOIN traj_cs t ON t.zoom = a.zoom
    WHERE CST_Intersects(t.traj_cells, a.area_cells)
)

SELECT
    '01_area_poly'::text AS info,
    ap.geom              AS geom
FROM area_poly ap

UNION ALL
SELECT
    '02_area_cs_multipolygon' AS info,
    cst_asmultipolygon(a.area_cells, a.zoom) AS geom
FROM area_cs a

UNION ALL
SELECT
    '03_traj_cs_multipolygon' AS info,
    cst_asmultipolygon(t.traj_cells, t.zoom) AS geom
FROM traj_cs t

UNION ALL
SELECT
--     'MMSI: 265504660 (z21) 5.2% coverage' AS info,
--     'MMSI: 265504660 (z17) 17.5% coverage' AS info,
    'MMSI: 636018490 (z13) 5.34% coverage' AS info,
    cst_asmultipolygon(i.inter_cells, i.zoom) AS geom
FROM intersection_cs i;
