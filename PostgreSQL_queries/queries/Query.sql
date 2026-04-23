SELECT CST_Intersects(ARRAY[1,2,3]::cellstring, ARRAY[2,4]::cellstring);
SELECT cst_intersection(ARRAY[1,2,3]::cellstring, ARRAY[2,3]::cellstring);
SELECT CST_Union(ARRAY[1,3]::cellstring, ARRAY[2,3]::cellstring);
SELECT CST_Difference(ARRAY[1,2,3]::cellstring, ARRAY[2]::cellstring);
SELECT CST_Contains(ARRAY[1,2,3]::cellstring, ARRAY[2,3]::cellstring);
