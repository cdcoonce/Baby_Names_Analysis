-- OBJECTIVE 1: TRACK CHANGES IN POPULARITY
use baby_names_db;
-- 1. Find the overall most popular girl and boy names and show how they have changed in popularity rankings over the years.

(SELECT 
	Gender,
	Name,
    SUM(Births) AS Births
FROM names
WHERE Gender = 'M'
GROUP BY Gender, Name
ORDER BY Births DESC
LIMIT 5) -- Michael, Christopher, Matthew, Joshua, Daniel
UNION
(SELECT 
	Gender,
	Name,
    SUM(Births) AS Births
FROM names
WHERE Gender = 'F'
GROUP BY Gender, Name
ORDER BY Births DESC
LIMIT 5); -- Jessica, Ashley, Emily, Sarah, Jennifer

SELECT *
FROM
	(WITH girl_names AS (SELECT
		Year,
		Name, 
		SUM(Births) AS Births
	FROM names
	WHERE Gender = 'F'
	GROUP BY Year, Name)

	SELECT 
		Year,
		Name,
		ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
	FROM girl_names) AS popular_girl_names
WHERE Name = 'Jessica';

SELECT *
FROM
	(WITH boy_names AS (SELECT
		Year,
		Name, 
		SUM(Births) AS Births
	FROM names
	WHERE Gender = 'M'
	GROUP BY Year, Name)

	SELECT 
		Year,
		Name,
		ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
	FROM boy_names) AS popular_boy_names
WHERE Name = 'Michael';
    

-- 2. Find the names with the biggest jumps in popularity from the first year of the data set to the last year

WITH names_1980 AS (
	WITH all_names AS (SELECT
		Year,
		Name, 
		SUM(Births) AS Births
	FROM names
	GROUP BY Year, Name)

	SELECT 
		Year,
		Name,
		ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
	FROM all_names
    WHERE Year = 1980),
    
names_2009 AS (    
	WITH all_names AS (SELECT
		Year,
		Name, 
		SUM(Births) AS Births
	FROM names
	GROUP BY Year, Name)

	SELECT 
		Year,
		Name,
		ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
	FROM all_names
    WHERE Year = 2009)
    
    SELECT t1.Name,
		t1.Year,
        t1.popularity,
        t2.Year,
        t2.popularity,
		CAST(t2.popularity AS SIGNED) - CAST(t1.popularity AS SIGNED) AS diff
    FROM names_1980 t1 INNER JOIN names_2009 t2
    ON t1.Name=t2.Name
    ORDER BY diff;