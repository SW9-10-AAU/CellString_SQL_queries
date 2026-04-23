SELECT (ARRAY[1,2]::cellstring) && (ARRAY[2,3]::cellstring) AS Intersects;
SELECT (ARRAY[1,2]::cellstring) & (ARRAY[2,3]::cellstring) AS Intersection;
SELECT (ARRAY[1,2]::cellstring) | (ARRAY[2,3]::cellstring) AS Union;
SELECT (ARRAY[1,3]::cellstring) - (ARRAY[3]::cellstring) AS Difference;
SELECT (ARRAY[1,2,3]::cellstring) @>~ (ARRAY[2,3]::cellstring) AS Contains;
