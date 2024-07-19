CREATE TABLE `waterdata` (
  `index` int,
  `county` text,
  `gallons_from_great_lakes` int,
  `gallons_from_groundwater`int,
  `gallons_from_inland_surface` int,
  `total_gallons_all_sources` int,
  `industry` text,
  `year` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Create staging table to reduce risk of losing data
CREATE TABLE waterdata_staging
LIKE waterdata;

INSERT waterdata_staging
SELECT *
FROM waterdata;

ALTER TABLE waterdata_staging 
MODIFY gallons_from_groundwater DOUBLE,
MODIFY gallons_from_inland_surface DOUBLE,
MODIFY total_gallons_all_sources DOUBLE,
MODIFY gallons_from_great_lakes DOUBLE;

-- Convert gallons to billions for more readable format
UPDATE waterdata_staging
SET 
    gallons_from_groundwater = ROUND(gallons_from_groundwater / 1000000000, 2),
    gallons_from_inland_surface = ROUND(gallons_from_inland_surface / 1000000000, 2),
    total_gallons_all_sources = ROUND(total_gallons_all_sources / 1000000000, 2),
    gallons_from_great_lakes = ROUND(gallons_from_great_lakes / 1000000000, 2);


SELECT * 
FROM waterdata_staging;



-------------------- EXPLORATORY ANALYSIS ---------------------------------------------------------------------------------------------------



-- Total water usage from each year between 2013-2022 to evaluate the usage over time 
SELECT year, 
    ROUND(SUM(gallons_from_great_lakes), 2) AS total_gallons_greatlakes, 
    ROUND(SUM(gallons_from_groundwater), 2) AS total_gallons_groundwater,
    ROUND(SUM(gallons_from_inland_surface), 2) AS total_gallons_inlandsurface,  
    ROUND(SUM(total_gallons_all_sources), 2) AS total_gallons_billions
FROM waterdata_staging
GROUP BY year
ORDER BY year ASC;


-- Total water usage as per industry overall to evaluate which industries are the biggest offender
SELECT industry, 
	ROUND(SUM(gallons_from_great_lakes), 2) AS total_gallons_greatlakes, 
	ROUND(SUM(gallons_from_groundwater), 2) AS total_gallons_groundwater,
    ROUND(SUM(gallons_from_inland_surface), 2) AS total_gallons_inlandsurface,  
	ROUND(SUM(total_gallons_all_sources), 2) AS total_gallons_billions
FROM waterdata_staging
GROUP BY industry
ORDER BY total_gallons_billions desc;

-- Total water usage as per county overall to evaluate which counties are the biggest offender
SELECT county, 
	ROUND(SUM(gallons_from_great_lakes), 2) AS total_gallons_greatlakes, 
	ROUND(SUM(gallons_from_groundwater), 2) AS total_gallons_groundwater,
    ROUND(SUM(gallons_from_inland_surface), 2) AS total_gallons_inlandsurface,  
	ROUND(SUM(total_gallons_all_sources), 2) AS total_gallons_billions
FROM waterdata_staging
GROUP BY county
ORDER BY total_gallons_billions desc;


-- Percentage that each source madeup of the total gallons used each year
SELECT year, 
ROUND((SUM(gallons_from_great_lakes)*100) / SUM(total_gallons_all_sources),2) AS pct_great_lakes,
ROUND((SUM(gallons_from_inland_surface)*100) / SUM(total_gallons_all_sources),2) AS pct_inland_surface,
ROUND((SUM(gallons_from_groundwater)*100) / SUM(total_gallons_all_sources),2) AS pct_groundwater
FROM waterdata_staging
GROUP BY year
ORDER BY year;

-- Rolling total of Monroe county(responsible for most gallons total) total gallons of the years
WITH Rolling_Total AS
(
SELECT county, year, 
	ROUND(SUM(total_gallons_all_sources),2) AS total_gallons
FROM waterdata_staging
WHERE county = "Monroe"
GROUP BY year
ORDER BY 2 ASC
)

SELECT county, year, total_gallons, ROUND(SUM(total_gallons) OVER(ORDER BY year),2) AS rolling_total
FROM Rolling_Total
;

-- Rolling total of Public Water Supply Industry(responsible for most gallons total) total gallons of the years
WITH Rolling_Total AS
(
SELECT industry, year,  ROUND(SUM(total_gallons_all_sources),2) AS total_gallons
FROM waterdata_staging
WHERE industry = "Public Water Supply"
GROUP BY year
ORDER BY 2 ASC
)

SELECT industry, year, total_gallons,  ROUND(SUM(total_gallons) OVER(ORDER BY year),2) AS rolling_total
FROM Rolling_Total
;

