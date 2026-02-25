-- Create cellstring values
SELECT ARRAY[1, 2, 3]::cellstring AS a, ARRAY[2, 3, 4]::cellstring AS b;

-- Intersect two cellstrings
SELECT CST_Intersects(a, b) FROM (SELECT ARRAY[1, 2, 3]::cellstring AS a, ARRAY[2, 3, 4]::cellstring AS b) AS subquery;

-- Union of two cellstrings
SELECT CST_Union(a, b) FROM (SELECT ARRAY[1, 2, 3]::cellstring AS a, ARRAY[2, 3, 4]::cellstring AS b) AS subquery;
