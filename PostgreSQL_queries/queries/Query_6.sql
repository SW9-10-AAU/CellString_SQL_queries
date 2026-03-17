SELECT
    ls.geom,
    cst_aslinestring(cs.cellstring_z13, 13) as decoded_trajectory_z13,
    cst_hausdorffdistance(cs.cellstring_z13, ls.geom, 13) as hausdorff_distance_z13,
    cst_aslinestring(cs.cellstring_z17, 17) as decoded_trajectory_z17,
    cst_hausdorffdistance(cs.cellstring_z17, ls.geom, 17) as hausdorff_distance_z17,
    cst_aslinestring(cs.cellstring_z21, 21) as decoded_trajectory_z21,
    cst_hausdorffdistance(cs.cellstring_z21, ls.geom, 21) as hausdorff_distance_z21
FROM prototype2.trajectory_ls ls
JOIN prototype2.trajectory_cs cs
    ON ls.trajectory_id = cs.trajectory_id
WHERE
    ls.trajectory_id = 8;