# Baby Names Analysis

This project explores a **U.S. baby names** database, analyzing name popularity, trends over time, regional differences, and unique naming patterns. The data includes baby names from various states and spans the years 1980 through 2009 (based on the queries below).

## Table of Contents

1. [Project Description](#project-description)  
2. [Data Structure](#data-structure)  
3. [Objectives & Queries](#objectives--queries)  
   - [Objective 1: Track Changes in Popularity](#objective-1-track-changes-in-popularity)  
   - [Objective 2: Compare Popularity Across Decades](#objective-2-compare-popularity-across-decades)  
   - [Objective 3: Compare Popularity Across Regions](#objective-3-compare-popularity-across-regions)  
   - [Objective 4: Explore Unique Names](#objective-4-explore-unique-names)  
4. [Key Findings](#key-findings)

---

## Project Description

We aim to answer questions about naming trends in the United States, such as:

- Which names (male and female) have been the most popular overall?
- How have name rankings changed over time?
- How does popularity differ across regions?
- Which names are truly unique or androgynous (used by both genders)?

The **SQL scripts** below demonstrate how these questions were tackled, with highlights from the resulting data.

---

## Data Structure

- **Table:** `names`  
  **Columns:**
  - `Year` (int) - Year of birth  
  - `Name` (varchar) - Baby name  
  - `Gender` (char) - `M` or `F`  
  - `State` (char) - 2-letter U.S. state code  
  - `Births` (int) - Number of babies given that name in that year/state  

- **Table:** `regions`  
  **Columns:**
  - `State` (char) - 2-letter U.S. state code  
  - `Region` (varchar) - One of: `South`, `Midwest`, `Pacific`, `Mid_Atlantic`, `Mountain`, `New_England`  

We also create **Common Table Expressions (CTEs)** and use window functions (`RANK()`, `ROW_NUMBER()`) to facilitate advanced queries.

---

## Objectives & Queries

### Objective 1: Track Changes in Popularity

#### 1) Overall Most Popular Boy and Girl Names

```sql
USE baby_names_db;

-- Top 5 male names by total births
(
  SELECT Gender, Name, SUM(Births) AS Births
  FROM names
  WHERE Gender = 'M'
  GROUP BY Gender, Name
  ORDER BY Births DESC
  LIMIT 5
)
UNION
-- Top 5 female names by total births
(
  SELECT Gender, Name, SUM(Births) AS Births
  FROM names
  WHERE Gender = 'F'
  GROUP BY Gender, Name
  ORDER BY Births DESC
  LIMIT 5
);
```

#### 2) Popularity Over Time for Specific Names

We look at “Jessica” (most popular female) and “Michael” (most popular male) to see how their ranks changed by year.

```sql
-- Ranking girls' names by year
WITH girl_names AS (
    SELECT Year, Name, SUM(Births) AS Births
    FROM names
    WHERE Gender = 'F'
    GROUP BY Year, Name
)
SELECT Year, Name,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
FROM girl_names
WHERE Name = 'Jessica';

-- Ranking boys' names by year
WITH boy_names AS (
    SELECT Year, Name, SUM(Births) AS Births
    FROM names
    WHERE Gender = 'M'
    GROUP BY Year, Name
)
SELECT Year, Name,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
FROM boy_names
WHERE Name = 'Michael';
```

#### 3) Biggest Jumps in Popularity (1980 to 2009)

```sql
WITH names_1980 AS (
    WITH all_names AS (
        SELECT Year, Name, SUM(Births) AS Births
        FROM names
        GROUP BY Year, Name
    )
    SELECT Year, Name,
           ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
    FROM all_names
    WHERE Year = 1980
),

names_2009 AS (
    WITH all_names AS (
        SELECT Year, Name, SUM(Births) AS Births
        FROM names
        GROUP BY Year, Name
    )
    SELECT Year, Name,
           ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Births DESC) AS popularity
    FROM all_names
    WHERE Year = 2009
)

SELECT t1.Name,
       t1.Year,
       t1.popularity,
       t2.Year,
       t2.popularity,
       CAST(t2.popularity AS SIGNED) - CAST(t1.popularity AS SIGNED) AS diff
FROM names_1980 t1
INNER JOIN names_2009 t2 
    ON t1.Name = t2.Name
ORDER BY diff;
```

---

### Objective 2: Compare Popularity Across Decades

#### 1) For Each Year: Top 3 Girl Names and Top 3 Boy Names

```sql
WITH male_births_per_year AS (
    SELECT Year, Name, Gender, SUM(Births) AS births
    FROM names
    WHERE Gender = 'M'
    GROUP BY Year, Name, Gender
),
female_births_per_year AS (
    SELECT Year, Name, Gender, SUM(Births) AS births
    FROM names
    WHERE Gender = 'F'
    GROUP BY Year, Name, Gender
),
male_ranked_names AS (
    SELECT *,
           RANK() OVER (PARTITION BY Year ORDER BY births DESC) AS births_rank
    FROM male_births_per_year
),
female_ranked_names AS (
    SELECT *,
           RANK() OVER (PARTITION BY Year ORDER BY births DESC) AS births_rank
    FROM female_births_per_year
),
male_top_3 AS (
    SELECT *
    FROM male_ranked_names
    WHERE births_rank <= 3
),
female_top_3 AS (
    SELECT *
    FROM female_ranked_names
    WHERE births_rank <= 3
)
SELECT mt.Year,
       mt.births_rank AS 'Rank',
       mt.Name AS Male,
       ft.Name AS Female
FROM male_top_3 mt
INNER JOIN female_top_3 ft
  ON mt.Year = ft.Year
 AND mt.births_rank = ft.births_rank;
 ```

#### 2) For Each Decade: Top 3 Girl Names and Top 3 Boy Names

 ```sql
 WITH male_births_per_year AS (
    SELECT Year, Name, Gender, SUM(Births) AS births
    FROM names
    WHERE Gender = 'M'
    GROUP BY Year, Name, Gender
),
female_births_per_year AS (
    SELECT Year, Name, Gender, SUM(Births) AS births
    FROM names
    WHERE Gender = 'F'
    GROUP BY Year, Name, Gender
),
male_decade AS (
    SELECT CASE
             WHEN Year LIKE '__8_' THEN "1980s"
             WHEN Year LIKE '__9_' THEN "1990s"
             WHEN Year LIKE '__0_' THEN "2000s"
             ELSE "2010"
           END AS Decade,
           Name,
           SUM(births) AS total_births
    FROM male_births_per_year
    GROUP BY Decade, Name
),
female_decade AS (
    SELECT CASE
             WHEN Year LIKE '__8_' THEN "1980s"
             WHEN Year LIKE '__9_' THEN "1990s"
             WHEN Year LIKE '__0_' THEN "2000s"
             ELSE "2010"
           END AS Decade,
           Name,
           SUM(births) AS total_births
    FROM female_births_per_year
    GROUP BY Decade, Name
),
male_ranks AS (
    SELECT Decade,
           RANK() OVER (PARTITION BY Decade ORDER BY total_births DESC) AS name_rank,
           Name,
           total_births
    FROM male_decade
),
female_ranks AS (
    SELECT Decade,
           RANK() OVER (PARTITION BY Decade ORDER BY total_births DESC) AS name_rank,
           Name,
           total_births
    FROM female_decade
)
SELECT mr.Decade,
       mr.name_rank,
       mr.Name AS Male,
       fr.Name AS Female
FROM male_ranks mr
INNER JOIN female_ranks fr
    ON mr.Decade = fr.Decade
   AND mr.name_rank = fr.name_rank
WHERE mr.name_rank <= 3 OR fr.name_rank <= 3;
```

---

### Objective 3: Compare Popularity Across Regions

#### 1) Total Births by Region

We add MI (Michigan) to the Midwest region and then sum births by region:

```sql
INSERT INTO regions (State, Region)
VALUES ('MI', 'Midwest');

WITH regions_added AS (
    SELECT Region, Births, Name
    FROM names n
    LEFT JOIN regions r
        ON n.state = r.state
)
SELECT Region,
       SUM(Births) AS Births
FROM regions_added
GROUP BY Region
ORDER BY Births DESC;
```

#### 2) Top 3 Boy and Girl Names Within Each Region

```sql
WITH regions_added_male AS (
    SELECT Region, Gender, Name, Births
    FROM names n
    LEFT JOIN regions r
        ON n.state = r.state
    WHERE Gender = 'M'
),
regions_added_female AS (
    SELECT Region, Gender, Name, Births
    FROM names n
    LEFT JOIN regions r
        ON n.state = r.state
    WHERE Gender = 'F'
),
male_summed AS (
    SELECT Region, Name, SUM(Births) AS Births
    FROM regions_added_male
    GROUP BY Region, Name
),
female_summed AS (
    SELECT Region, Name, SUM(Births) AS Births
    FROM regions_added_female
    GROUP BY Region, Name
),
male_ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY Region ORDER BY Births DESC) AS Births_Rank
    FROM male_summed
),
female_ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY Region ORDER BY Births DESC) AS Births_Rank
    FROM female_summed
)
SELECT mr.Region,
       mr.Name,
       mr.Births,
       mr.Births_Rank AS 'Regional Birth Rank',
       fr.Name,
       fr.Births,
       fr.Region
FROM male_ranked mr
INNER JOIN female_ranked fr
   ON mr.Region = fr.Region
  AND mr.Births_Rank = fr.Births_Rank
WHERE mr.Births_Rank <= 3
ORDER BY mr.Region, mr.Births DESC;
```

---

### Objective 4: Explore Unique Names

#### 1) Top 10 Most Popular Androgynous Names

Names given to both males and females at least once.

```sql
SELECT Name,
       SUM(Births) AS total_births,
       COUNT(DISTINCT Gender) AS num_genders
FROM names
GROUP BY Name
HAVING num_genders = 2
ORDER BY total_births DESC
LIMIT 10;
```

#### 2) Shortest & Longest Names and Their Popularity

```sql
-- Find name lengths, identify min and max
SELECT Name, LENGTH(Name) AS name_length
FROM names
ORDER BY name_length;          -- For shortest

SELECT Name, LENGTH(Name) AS name_length
FROM names
ORDER BY name_length DESC;     -- For longest

-- Check popularity of exactly those shortest (length=2) and longest (length=15) names
WITH short_long_names AS (
    SELECT *
    FROM names
    WHERE LENGTH(Name) IN (2, 15)
)
SELECT Name,
       SUM(Births) AS num_babies
FROM short_long_names
GROUP BY Name
ORDER BY num_babies DESC;
```

#### 3) State with Highest Percentage of Babies Named “Chris” (Stakeholder's Name)

```sql
WITH number_chris AS (
    SELECT State, SUM(Births) AS sum_chris
    FROM names
    WHERE Name = 'Chris'
    GROUP BY State, Name
),
number_births AS (
    SELECT State, SUM(Births) AS sum_births
    FROM names
    GROUP BY State
)
SELECT nc.State,
       sum_chris / sum_births * 100 AS pct_chris
FROM number_chris nc
INNER JOIN number_births nb
   ON nc.State = nb.State
ORDER BY pct_chris DESC;
```

---

Key Findings

1. Overall Top Names (1980–2009)
   - Boys: Michael, Christopher, Matthew, Joshua, Daniel
   - Girls: Jessica, Ashley, Emily, Sarah, Jennifer
2. Popularity Over the Years
   - Jessica and Michael remained extremely popular throughout the 1980s and 1990s. Michael often ranked #1 for boys, while Jessica took #1 for girls in many years.
3. Biggest Popularity Jumps (1980 to 2009)
   - Certain names (e.g., Aidan, Skylar, Macy) showed significant movement in rank, reflecting changing cultural trends.
4. Decade Comparisons
   - 1980s: Michael & Jessica dominated.
   - 1990s: Michael & Jessica still at the top, with Christopher, Ashley, and Emily also ranking highly.
   - 2000s: Jacob, Emily, Michael, and Madison emerge on top.
5. Regional Trends
   - The South has the largest total number of births.
   - Popular boy names across multiple regions include Michael, Christopher, Joshua.
   - Popular girl names frequently include Jessica, Ashley, Emily.
6. Unique/Androgynous Names
   - Top 10 names used by both genders included Michael, Christopher, Matthew, Jessica, and more.
   - These appear to have been used for both boys and girls, though often with differing frequencies.
7. Shortest vs. Longest Names
   - Shortest names (2 letters) include Ty, Bo, Jo, Om, Al; Ty had over 46k births.
   - Longest names (15 letters) include Franciscojavier, Ryanchristopher, Johnchristopher, Mariadelosangel.
8. Highest Percentage of Babies Named “Chris”
   - New York leads with approx. 0.0324% of babies named “Chris,” followed by Louisiana (0.0308%) and Texas (0.0291%).

---

## Acknowledgments

This project was completed as part of a guided learning experience with **Maven Analytics**. Special thanks to Maven Analytics for providing structured guidance and high-quality datasets to enhance analytical skills.
