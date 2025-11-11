-- Visualise trajectories and stops
-- LineString/Polygon and its corresponding CellString representation

-- Trajectory
SELECT
    ls.trajectory_id,
    ls.mmsi,
    ls.geom AS trajectory_geom,
    ls_experiment.cellids_to_polygons(cs.cellstring) AS trajectory_cells
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
  ON ls.trajectory_id = cs.trajectory_id
WHERE ls.trajectory_id IN (12);


-- Stop
SELECT
    ls.stop_id,
    ls.mmsi,
    ls.geom AS stop_geom,
    ls_experiment.cellids_to_polygons(cs.cellstring) AS stop_cells
FROM prototype2.stop_poly ls
JOIN prototype2.stop_cs cs
  ON ls.stop_id = cs.stop_id
WHERE ls.stop_id IN (5291);


-- Area (zoom level 21)
SELECT
    ls.area_id,
    ls.name,
    ls.geom AS stop_geom,
    ls_experiment.cellids_to_polygons(cs.cellstring_z21) AS area_cells
FROM benchmark.area_poly ls
JOIN benchmark.area_cs cs
  ON ls.area_id = cs.area_id
WHERE ls.area_id IN (2);
