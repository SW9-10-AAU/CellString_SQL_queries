DROP INDEX IF EXISTS prototype2.trajectory_cellstring_z13_gin_idx;

CREATE INDEX trajectory_cellstring_z13_gin_idx
ON prototype2.trajectory_cs
USING GIN (cellstring_z13 gin__int_ops);


CREATE INDEX trajectory_cellstring_z13_gin_idx
ON prototype2.trajectory_cs
USING GIN (cellstring_z13);