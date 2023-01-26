-- Data Exploartion on Indian Census Dataset

-- Skills used Joins, Temp Tables, Suqueries, Union, Window Functions, Aggregate Function. 

-- To view the Dataset

SELECT * FROM Data.dbo.Data1

SELECT * FROM Data.dbo.Data2

-- Finding the number of rows in the dataset

SELECT COUNT(*) FROM Data.dbo.Data1

SELECT COUNT(*) FROM Data.dbo.Data2

-- Return results of 'Tamil Nadu' and  'Karnataka'

SELECT * FROM Data.dbo.Data1 WHERE State IN ('Tamil Nadu' , 'Karnataka')

-- Calculate the Population of India

SELECT SUM(Population) as Indian_Population FROM Data.dbo.Data2

-- Calculate Average Growth of India

SELECT AVG(Growth) * 100 as Avg_Growth_Rate FROM Data.dbo.Data1

-- Calculate Statewise Average Growth Rate

SELECT State, AVG(Growth) * 100 as Avg_Growth_Rate FROM Data.dbo.Data1 GROUP BY State

-- Calculate Statewise Sex Ratio and Return results showing highest to lowest

SELECT State, ROUND(AVG(Sex_Ratio),0) as Avg_Sex_Ratio FROM Data.dbo.Data1 GROUP BY State ORDER BY Avg_Sex_Ratio DESC

-- Calculate Avg Literacy Ratio and Return results where the ALR > 85

SELECT State, ROUND(AVG(Literacy),0) as Avg_Literacy_Ratio FROM Data.dbo.Data1 
GROUP BY State
HAVING ROUND(AVG(Literacy),0) > 85
ORDER BY Avg_Literacy_Ratio DESC

-- Calculate Top 3 states showing highest Growth Rate

SELECT TOP 3 State, AVG(Growth) * 100 as Avg_Growth_Rate FROM Data.dbo.Data1 GROUP BY State ORDER BY Avg_Growth_Rate DESC

-- Calculate the bottom 3 states par with Growth Rate

SELECT TOP 3 State, AVG(Growth) * 100 as Avg_Growth_Rate FROM Data.dbo.Data1 GROUP BY State ORDER BY Avg_Growth_Rate ASC


-- TOP 3  and BOTTOM 3 states based on Literacy Rates ( With the use of Temp Tables)

DROP TABLE IF EXISTS #topstates
CREATE TABLE #topstates
 ( State nvarchar(255),
   Top_State float
   )

INSERT INTO #topstates
SELECT State, ROUND(AVG(Literacy),0) AS Avg_Literacy_Ratio 
FROM Data.dbo.Data1
GROUP BY State
ORDER BY Avg_Literacy_Ratio DESC

SELECT TOP 3 * FROM #topstates ORDER BY #topstates.Top_State DESC 


DROP TABLE IF EXISTS #bottomstates
CREATE TABLE #bottomstates
 ( State nvarchar(255),
   Bottom_State float
   )

INSERT INTO #bottomstates
SELECT State, ROUND(AVG(Literacy),0) AS Avg_Literacy_Ratio 
FROM Data.dbo.Data1
GROUP BY State
ORDER BY Avg_Literacy_Ratio DESC

SELECT TOP 3 * FROM #bottomstates ORDER BY #bottomstates.Bottom_State ASC

-- Using UNION operator to combine results

SELECT * FROM (SELECT TOP 3 * FROM #topstates ORDER BY #topstates.Top_State DESC) a
UNION
SELECT * FROM (SELECT TOP 3 * FROM #bottomstates ORDER BY #bottomstates.Bottom_State ASC) b

-- Sates starting with Letter A

SELECT * FROM Data.dbo.Data1 WHERE State LIKE 'A%'

-- Sates starting with Letter A or Ending with Letter H

SELECT DISTINCT State FROM Data.dbo.Data1 WHERE State LIKE 'A%' OR State LIKE '%H'

--Calculate male and female from Sex Ratio and Population (Using Joins, Temp Tables, Subqueries)

SELECT d.State, SUM(d.Males) AS Total_Males, SUM(d.Females) AS Total_Females FROM
(SELECT c.District, c.State, ROUND(c.Population/(c.Sex_ratio+1),0) AS Males, ROUND((c.Population*c.Sex_ratio)/(c.Sex_ratio+1),0) AS Females FROM
(SELECT a.District, a.State, a.Sex_Ratio/1000 Sex_ratio,b.Population
FROM Data.dbo.Data1 a 
INNER JOIN Data.dbo.Data2 b
ON a.District = b.District) c ) d
GROUP BY d.State

-- Calculate Literate people and illiterate poeople

SELECT c.State, SUM(Literate_People) AS Total_Literate_Pop , SUM(Illiterate_People) AS Total_Illterate_Pop FROM
(SELECT d.District, d.State, ROUND(d.Literacy_ratio*d.Population,0) AS Literate_People, ROUND((1-d.Literacy_Ratio)*d.Population,0) AS Illiterate_People FROM
(SELECT a.District, a.State, a.Literacy/100 AS Literacy_ratio,b.Population
FROM Data.dbo.Data1 a 
INNER JOIN Data.dbo.Data2 b
ON a.District = b.District) d) c
GROUP BY c.State

-- Calculate Population as per previous census using current population and growth rate

SELECT d.State, SUM(d.Previous_Census_Population) AS Total_Previous_Census_Population, SUM(d.Current_Population) AS Total_Current_Population FROM
(SELECT c.District, c.State, ROUND(c.Population/(1+c.Growth),0) AS Previous_Census_Population , c.Population AS Current_Population FROM 
(SELECT a.District, a.State, a.Growth/100 AS Growth ,b.Population FROM Data.dbo.Data1 a INNER JOIN Data.dbo.Data2 b ON a.District = b.District) c) d
GROUP BY d.State

-- Population vs Area

SELECT g.Total_Area/g.Previous_Census_Population AS Previous_Population_vs_Area , g.Total_Area/g.Current_Population AS Current_Population_vs_Area  FROM
(SELECT q.*, r.Total_Area FROM (

SELECT '1' AS keyy,n.* FROM
(SELECT SUM(m.Previous_Census_Population) AS Previous_Census_Population, SUM(m.Current_Population) AS Current_Population FROM
(SELECT d.State, SUM(d.Previous_Census_Population) AS Previous_Census_Population, SUM(d.Current_Population) AS Current_Population FROM
(SELECT c.District, c.State, ROUND(c.Population/(1+c.Growth),0) AS Previous_Census_Population , c.Population AS Current_Population FROM 
(SELECT a.District, a.State, a.Growth/100 AS Growth ,b.Population FROM Data.dbo.Data1 a INNER JOIN Data.dbo.Data2 b ON a.District = b.District) c) d
GROUP BY d.State)m)n) q INNER JOIN (


SELECT '1' AS keyy,z.* FROM
(SELECT SUM(Area_Km2) AS Total_Area FROM Data.dbo.Data2)z) r ON q.keyy = r.keyy) g


-- Using Window Function return Top 3 Districts from each state with highest Literacy Rate

SELECT a.* FROM
(SELECT District, State, Literacy, RANK() OVER(PARTITION BY State ORDER BY Literacy DESC) Rnk FROM Data.dbo.Data1)a
WHERE a.Rnk IN (1,2,3) ORDER BY State