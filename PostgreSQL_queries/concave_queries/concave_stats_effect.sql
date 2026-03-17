--Stats
SELECT
    AVG(cardinality(cellstring_z13)) AS avg_z13,
    MIN(cardinality(cellstring_z13)) AS min_z13,
    MAX(cardinality(cellstring_z13)) AS max_z13,

    AVG(cardinality(cellstring_z17)) AS avg_z17,
    MIN(cardinality(cellstring_z17)) AS min_z17,
    MAX(cardinality(cellstring_z17)) AS max_z17,

    AVG(cardinality(cellstring_z21)) AS avg_z21,
    MIN(cardinality(cellstring_z21)) AS min_z21,
    MAX(cardinality(cellstring_z21)) AS max_z21
FROM prototype2.concave_stop_cs;

SELECT
    AVG(cardinality(cellstring_z13)) AS avg_z13,
    MIN(cardinality(cellstring_z13)) AS min_z13,
    MAX(cardinality(cellstring_z13)) AS max_z13,

    AVG(cardinality(cellstring_z17)) AS avg_z17,
    MIN(cardinality(cellstring_z17)) AS min_z17,
    MAX(cardinality(cellstring_z17)) AS max_z17,

    AVG(cardinality(cellstring_z21)) AS avg_z21,
    MIN(cardinality(cellstring_z21)) AS min_z21,
    MAX(cardinality(cellstring_z21)) AS max_z21
FROM prototype2.stop_cs;


--Table from paper on cardinality and points
WITH point_counts AS (
    SELECT
        stop.stop_id,
        ST_NPoints(stop.geom) AS num_points
    FROM prototype2.concave_stop_poly stop
),
total_points AS (
    SELECT SUM(num_points) AS total_points
    FROM point_counts
)

SELECT 'z13' AS zoom,
       SUM(cardinality(cellstring_z13)) AS cellstring_cardinality,
       (SELECT total_points FROM total_points) AS num_points
FROM prototype2.concave_stop_cs

UNION ALL

SELECT 'z17',
       SUM(cardinality(cellstring_z17)),
       (SELECT total_points FROM total_points)
FROM prototype2.concave_stop_cs

UNION ALL

SELECT 'z21',
       SUM(cardinality(cellstring_z21)),
       (SELECT total_points FROM total_points)
FROM prototype2.concave_stop_cs;


