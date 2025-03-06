-- OBJECTIVE 2: COMPARE POPULARITY ACROSS DECADES

-- 1. For each year, return the 3 most popular girl names and 3 most popular boy names.
WITH male_births_per_year AS
	(SELECT
		Year,
		Name,
        GENDER,
		SUM(Births) as births
	FROM names
    WHERE Gender = 'M'
	GROUP BY Year, Name, GENDER
	ORDER BY Year, births DESC),
    
female_births_per_year AS
	(SELECT
		Year,
		Name,
        GENDER,
		SUM(Births) as births
	FROM names
    WHERE Gender = 'F'
	GROUP BY Year, Name, GENDER
	ORDER BY Year, births DESC),

male_ranked_names AS
	(SELECT * ,
		RANK() OVER (PARTITION BY Year ORDER BY births DESC) AS births_rank
	FROM male_births_per_year),
    
female_ranked_names AS
	(SELECT * ,
		RANK() OVER (PARTITION BY Year ORDER BY births DESC) AS births_rank
	FROM female_births_per_year),

male_top_3 AS
	(SELECT *
	FROM male_ranked_names
	WHERE births_rank <= 3),
    
female_top_3 AS
	(SELECT *
	FROM female_ranked_names
	WHERE births_rank <= 3)

SELECT mt.Year, mt.births_rank AS 'Rank', mt.Name AS Male, ft.Name AS Female
FROM male_top_3 mt
INNER JOIN female_top_3 ft
ON mt.births_rank = ft.births_rank
AND mt.Year = ft.Year;

-- 2. For each Decade, Return the 3 most popular girl names and 3 most popular boys names.
WITH male_births_per_year AS
	(SELECT
		Year,
		Name,
        GENDER,
		SUM(Births) as births
	FROM names
    WHERE Gender = 'M'
	GROUP BY Year, Name, GENDER
	ORDER BY Year, births DESC),
    
female_births_per_year AS
	(SELECT
		Year,
		Name,
        GENDER,
		SUM(Births) as births
	FROM names
    WHERE Gender = 'F'
	GROUP BY Year, Name, GENDER
	ORDER BY Year, births DESC),
    
male_decade AS
	(SELECT 
		CASE
			WHEN Year LIKE '__8_' THEN "1980s"
			WHEN Year LIKE '__9_' THEN "1990s"
			WHEN Year LIKE '__0_' THEN "2000s"
			ELSE "2010"
		END AS Decade,
		Name,
		SUM(births) AS total_births
	FROM male_births_per_year
	GROUP BY Decade, Name
	ORDER BY Decade, total_births DESC),
    
female_decade AS
	(SELECT 
		CASE
			WHEN Year LIKE '__8_' THEN "1980s"
			WHEN Year LIKE '__9_' THEN "1990s"
			WHEN Year LIKE '__0_' THEN "2000s"
			ELSE "2010"
		END AS Decade,
		Name,
		SUM(births) AS total_births
	FROM female_births_per_year
	GROUP BY Decade, Name
	ORDER BY Decade, total_births DESC),

male_ranks AS
	(SELECT Decade,
		RANK() OVER (PARTITION BY Decade ORDER BY total_births DESC) AS name_rank,
		Name,
		total_births
	FROM male_decade),
    
female_ranks AS
	(SELECT Decade,
		RANK() OVER (PARTITION BY Decade ORDER BY total_births DESC) AS name_rank,
		Name,
		total_births
	FROM female_decade)
    
SELECT mr.Decade,
	mr.name_rank,
    mr.Name AS Male,
    fr.Name AS Female
FROM male_ranks mr
INNER JOIN female_ranks fr
ON mr.name_rank = fr.name_rank
AND mr.Decade = fr.Decade
WHERE mr.name_rank <= 3 OR fr.name_rank <= 3;
    
    