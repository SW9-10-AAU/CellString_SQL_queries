
WITH trajB AS (
    SELECT *
    FROM prototype2.trajectory_ls
    WHERE ST_NumPoints(geom) < 100 AND ST_NumPoints(geom) > 90
)
SELECT trajA.trajectory_id, trajB.trajectory_id
FROM prototype2.trajectory_ls as trajA,trajB
WHERE trajA.mmsi <> trajB.mmsi
    AND trajA.trajectory_id <> trajB.trajectory_id
    AND ST_NumPoints(trajA.geom) < 100 AND ST_NumPoints(trajA.geom) > 90
    AND ST_Intersects(trajA.geom, trajB.geom);
