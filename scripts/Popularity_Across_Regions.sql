-- OBJECTIVE 3: Compare popularity across regions

-- 1. Return the number of babies born in each of the six regions (NOTE: The state of MI should be in the Midwest region)
INSERT INTO regions (State, Region)
VALUES ('MI', 'Midwest');

WITH regions_added AS
	(SELECT Region,
	Births, Name
	FROM names n
	LEFT JOIN regions r
	ON n.state = r.state)

SELECT Region, SUM(Births) AS Births
	FROM regions_added
	GROUP BY Region
	ORDER BY Births DESC;

-- 2. Return the 3 most popular girl names and 3 most popular boy names within each region

WITH regions_added_male AS
	(SELECT Region,
        Gender,
        Name,
        Births
	FROM names n
	LEFT JOIN regions r
	ON n.state = r.state
    WHERE Gender = 'M'),

regions_added_female AS
	(SELECT Region,
        Gender,
        Name,
        Births
	FROM names n
	LEFT JOIN regions r
	ON n.state = r.state
    WHERE Gender = 'F'),

male_summed AS
	(SELECT Region,
		Name,
		SUM(Births) AS Births
	FROM regions_added_male
	GROUP BY Region, Name),
    
female_summed AS
	(SELECT Region,
		Name,
		SUM(Births) AS Births
	FROM regions_added_female
	GROUP BY Region, Name),

male_ranked AS
	(SELECT *,
		RANK() OVER (PARTITION BY Region ORDER BY Births DESC) AS Births_Rank
	FROM male_summed),
    
female_ranked AS
	(SELECT *,
		RANK() OVER (PARTITION BY Region ORDER BY Births DESC) AS Births_Rank
	FROM female_summed)
    
SELECT mr.Region,
	mr.Name, mr.Births,
	mr.Births_Rank AS 'Regional Birth Rank',
    fr.Name, fr. Births,
    fr.Region
FROM male_ranked mr
INNER JOIN female_ranked fr
ON mr.Births_Rank = fr.Births_Rank
AND mr.Region = fr.Region
Where mr.Births_Rank <= 3
ORDER BY mr.Region, mr.Births DESC;