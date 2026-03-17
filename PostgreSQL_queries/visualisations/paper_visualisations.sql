-- mmsi: 636015105
-- traj id: 9316

WITH traj_id AS (
    SELECT 9316 AS id
)

-- LineString (cast to geometry for UNION compatibility)
SELECT
    ls.geom::geometry AS geom
FROM prototype2.trajectory_ls ls
JOIN traj_id t
    ON ls.trajectory_id = t.id

UNION ALL

-- Bresenham CellString
SELECT
    CST_AsMultiPolygon(cs.cellstring_z21, 21) AS geom
FROM prototype2.trajectory_cs cs
JOIN traj_id t
    ON cs.trajectory_id = t.id

UNION ALL

-- Supercover CellString
SELECT
    CST_AsMultiPolygon(sc.cellstring_z21, 21) AS geom
FROM prototype2.trajectory_supercover_cs sc
JOIN traj_id t
    ON sc.trajectory_id = t.id;



-- MBR of points

SELECT
  ST_Extent(geom) AS bbox
FROM prototype2.points;


SELECT
  ST_SetSRID(ST_Envelope(ST_Extent(geom))::geometry, 4326) AS mbr_geom
FROM prototype2.points
WHERE geom IS NOT NULL;

WITH s AS (
  SELECT
    ST_SRID(geom) AS srid,
    ST_Envelope(ST_Extent(geom))::geometry AS env
  FROM prototype2.points
  WHERE geom IS NOT NULL
  GROUP BY ST_SRID(geom)
)
SELECT
  ST_SetSRID(env, srid) AS mbr_geom
FROM s;


SELECT
  ST_SetSRID(
    ST_Envelope(
      ST_Extent(geom)
    )::geometry,
    4326
  ) AS mbr_geom
FROM (
  SELECT geom FROM prototype2.trajectory_ls WHERE geom IS NOT NULL

  UNION ALL
  SELECT geom
  FROM prototype2.stop_poly      WHERE geom IS NOT NULL

) s;


WITH mbr AS (
  SELECT
    ST_Envelope(ST_Extent(geom))::geometry AS geom
  FROM (
    SELECT geom FROM prototype2.trajectory_ls WHERE geom IS NOT NULL
    UNION ALL
    SELECT geom FROM prototype2.stop_poly      WHERE geom IS NOT NULL
  ) s
)
SELECT
  ST_Area(ST_Transform(ST_SetSRID(geom, 4326), 25832)) / 1e6 AS mbr_area_km2
FROM mbr;





-- COVERAGE OF AN AREA (trajectory covers area)
-- WITH chosen_mmsi AS (
--     SELECT 9316 AS chosen_mmsi
-- )

-- Show area_poly geom (Polygom)

-- Show area_cs cellstring geom (MultiPolygon)

-- Show the mmsi's trajectory CellStrings (multiPolygon)


-- Show the intersection between area cs and trajectory cs (multiPolygon)
    -- this is what i want to highligt in the geoviewer (to take a screenshot of it as a whole)



-- COVERAGE OF AN AREA (trajectory covers area) - layered geometries for GeoViewer
WITH
params AS (
    SELECT
        26::int     AS area_id,     -- <-- set your area
        636018490::bigint AS mmsi,       -- <-- set your MMSI
        13::int    AS zoom         -- <-- 13 / 17 / 21
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
    -- If you have multiple trajectories per MMSI, union them so you get "as a whole"
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


