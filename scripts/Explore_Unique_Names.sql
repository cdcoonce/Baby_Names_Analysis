-- OBJECTIVE 4: Explore unique names in the dataset

-- 1. Find the 10 most popular androgynous names (names given to both females and males)
SELECT Name, SUM(Births) AS total_births, COUNT(DISTINCT Gender) AS num_genders
From names
GROUP BY Name
HAVING num_Genders = 2
ORDER BY total_births DESC
LIMIT 10;

-- 2. Find the length of the shortest and longest names, and identify the most popular short names 
--    (those with the fewest characters) and long names (those with the most characters)

SELECT Name,
	LENGTH(Name) as name_length
FROM names
ORDER BY name_length; -- 2

SELECT Name,
	LENGTH(Name) as name_length
FROM names
ORDER BY name_length DESC; -- 15

WITH short_long_names AS
	(SELECT *
	FROM names
	WHERE LENGTH(Name) IN (2, 15))
    
SELECT Name,
	SUM(Births) AS num_babies
FROM short_long_names
Group BY name
ORDER BY num_babies DESC;

-- 3. The founder of Maven Analytics is named Chris. Find the state with the highest percent of babies named "Chris"
WITH number_chris AS (
	SELECT State,
		SUM(Births) AS sum_chris
	FROM names
	WHERE Name = 'Chris'
	GROUP BY State, Name
	ORDER BY sum_chris DESC),

number_births AS (
	SELECT State,
		SUM(Births) AS sum_births
	FROM names
	GROUP BY State)
    
SELECT nc.State,
	sum_chris / sum_births * 100 AS pct_chris
FROM number_chris nc
INNER JOIN number_births nb
ON nc.State = nb.State
ORDER BY pct_chris DESC;
