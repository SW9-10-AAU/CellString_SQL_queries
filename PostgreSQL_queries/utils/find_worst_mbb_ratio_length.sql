SELECT
    mmsi,
    trajectory_id,
    ST_Area(ST_Transform(ST_Envelope(geom), 3857)) AS mbr_area,
    ST_Length(ST_Transform(geom, 3857)) AS traj_length,
    CASE
        WHEN ST_Length(ST_Transform(geom, 3857)) > 0
        THEN ST_Area(ST_Transform(ST_Envelope(geom), 3857)) / ST_Length(ST_Transform(geom, 3857))
        ELSE NULL
    END AS mbr_length_ratio
FROM prototype2.trajectory_ls
WHERE ST_Length(ST_Transform(geom, 3857)) > 0
ORDER BY traj_length DESC;
