-- Find all other mmsi's that have trajectories that intersect a specific mmsi.
-- Hals-Egense mmsi: 219000873

--- ST_ version (~15s) (29 mmsis) ---
SELECT DISTINCT
    trajB.mmsi
FROM
    prototype1.trajectory_ls AS trajA,
    prototype1.trajectory_ls AS trajB
WHERE trajA.trajectory_id <> trajB.mmsi
    AND trajA.mmsi = 219000873
    AND ST_Intersects(trajA.geom, trajB.geom);

--- CellString version (~1.2s) (29 mmsis) ---
SELECT DISTINCT
    trajB.mmsi
FROM
    prototype1.trajectory_cs AS trajA,
    prototype1.trajectory_cs AS trajB
WHERE trajA.trajectory_id <> trajB.trajectory_id
    AND trajA.mmsi = 219000873
    AND CST_Intersects(trajA.cellstring, trajB.cellstring);