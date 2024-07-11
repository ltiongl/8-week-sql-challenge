-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #8 - Fresh Segments

USE fresh_segments;

-- A. Data Exploration and Cleansing
-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

DESCRIBE interest_metrics;

ALTER TABLE interest_metrics
DROP COLUMN month_year;

ALTER TABLE interest_metrics
ADD COLUMN month_year DATE AFTER `_year`;

UPDATE interest_metrics
SET month_year = DATE(CONCAT(_year, '-', _month, '-01'));

SELECT * FROM interest_metrics;

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

SELECT 
    month_year,
    COUNT(*) AS record_count
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;
    
-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics

DELETE FROM interest_metrics
WHERE interest_id IS NULL;

SELECT * FROM interest_metrics;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

SELECT
    COUNT(DISTINCT interest_id) AS not_in_map
FROM interest_metrics 
WHERE interest_id NOT IN (SELECT id FROM interest_map);

SELECT
    COUNT(DISTINCT id) AS not_in_metrics
FROM interest_map 
WHERE id NOT IN (SELECT interest_id FROM interest_metrics);

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

SELECT
    id,
    interest_name,
    COUNT(*) AS record_count
FROM 
    interest_metrics a
        JOIN
    interest_map b ON a.interest_id = b.id
GROUP BY id, interest_name
ORDER BY record_count DESC, id;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

SELECT
    _month,
    _year,
    month_year,
    interest_id,
    composition,
    index_value,
    ranking,
    percentile_ranking,
    interest_name,
    interest_summary,
    created_at,
    last_modified
FROM
    interest_metrics a 
        JOIN
    interest_map b ON a.interest_id = b.id
WHERE interest_id = 21246 AND month_year IS NOT NULL
ORDER BY month_year;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

SELECT
    month_year,
    created_at
FROM
    interest_metrics a 
        JOIN
    interest_map b ON a.interest_id = b.id
WHERE month_year < created_at;

-- Yes, they are valid. They are in the same month. Day from month_year can be neglected.alter

-- B. Interest Analysis
-- 1. Which interests have been present in all month_year dates in our dataset?

SELECT
    COUNT(DISTINCT month_year) AS month_year_count
FROM interest_metrics;

-- month_year_count = 14

SELECT
    interest_id,
    interest_name
FROM 
    interest_metrics a 
        JOIN
    interest_map b ON a.interest_id = b.id
GROUP BY interest_id, interest_name
HAVING COUNT(DISTINCT month_year) = 14;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id),
cte_id_count AS (
    SELECT
        month_count,
        COUNT(interest_id) AS id_count
    FROM cte_month_count
    GROUP BY month_count),
cte_cumulative AS (
    SELECT
        month_count,
        id_count,
        ROUND(SUM(id_count) OVER (ORDER BY month_count DESC) / (SELECT SUM(id_count) FROM cte_id_count) * 100, 2) AS cumulative_percentage
    FROM cte_id_count
    GROUP BY month_count, id_count)
SELECT
    * 
FROM cte_cumulative 
WHERE cumulative_percentage > 90;

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

-- total_month value is 6

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6)
SELECT
    COUNT(interest_id) AS total_data_removal
FROM
    interest_metrics
WHERE interest_id IN (SELECT interest_id FROM cte_month_count);

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6),
cte_present_id AS (
    SELECT
        month_year,
        COUNT(*) AS present_id_count
    FROM interest_metrics
    WHERE interest_id NOT IN (SELECT interest_id FROM cte_month_count)
    GROUP BY month_year),
cte_removed_id AS (
    SELECT
        month_year,
        COUNT(*) AS removed_id_count
    FROM interest_metrics
    WHERE interest_id IN (SELECT interest_id FROM cte_month_count)
    GROUP BY month_year)
SELECT 
    month_year,
    present_id_count,
    removed_id_count,
    ROUND(removed_id_count / (present_id_count + removed_id_count) * 100, 2) AS removed_percentage
FROM 
    cte_present_id 
        JOIN
    cte_removed_id USING (month_year)
ORDER BY month_year;

-- removed_percentage is not significant, the data points can be removed.

-- 5. After removing these interests - how many unique interests are there for each month?

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6)
SELECT
    month_year,
    COUNT(DISTINCT interest_id) AS unique_interests
FROM interest_metrics
WHERE interest_id NOT IN (SELECT interest_id FROM cte_month_count) AND month_year IS NOT NULL
GROUP BY month_year
ORDER BY month_year;
	
-- C. Segment Analysis
-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
-- Top 10 composition

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6),
cte_filtered_table AS (
    SELECT
        *
    FROM interest_metrics
    WHERE interest_id NOT IN (SELECT interest_id FROM cte_month_count)),
cte_top_composition AS (
    SELECT
        DISTINCT interest_id,
        MAX(composition) OVER (PARTITION BY interest_id) AS top_10_composition
    FROM cte_filtered_table
    ORDER BY top_10_composition DESC
    LIMIT 10)
SELECT
    i.month_year,
    c.interest_id,
    c.top_10_composition
FROM
    interest_metrics i
        JOIN
    cte_top_composition c ON i.composition = c.top_10_composition AND i.interest_id = c.interest_id
ORDER BY c.top_10_composition DESC;

-- Bottom 10 composition
WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6),
cte_filtered_table AS (
    SELECT
        *
    FROM interest_metrics
    WHERE interest_id NOT IN (SELECT interest_id FROM cte_month_count)),
cte_bottom_composition AS (
    SELECT
        DISTINCT interest_id,
        MAX(composition) OVER (PARTITION BY interest_id) AS bottom_10_composition
    FROM cte_filtered_table
    ORDER BY bottom_10_composition ASC
    LIMIT 10)
SELECT
    i.month_year,
    c.interest_id,
    c.bottom_10_composition
FROM
    interest_metrics i
        JOIN
    cte_bottom_composition c ON i.composition = c.bottom_10_composition AND i.interest_id = c.interest_id
ORDER BY c.bottom_10_composition ASC;

-- 2. Which 5 interests had the lowest average ranking value?

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6),
cte_filtered_table AS (
    SELECT
        *
    FROM interest_metrics
    WHERE interest_id NOT IN (SELECT interest_id FROM cte_month_count))
SELECT
    interest_id,
    interest_name,
    ROUND(AVG(ranking), 2) AS average_ranking
FROM 
    cte_filtered_table f
        JOIN
    interest_map m ON f.interest_id = m.id
GROUP BY interest_id, interest_name
ORDER BY average_ranking
LIMIT 5;

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?

SELECT * FROM interest_metrics;

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6),
cte_filtered_table AS (
    SELECT
        *
    FROM interest_metrics
    WHERE interest_id NOT IN (SELECT interest_id FROM cte_month_count))
SELECT
    interest_id,
    interest_name,
    ROUND(STDDEV_SAMP(percentile_ranking), 2) AS stddev_percentile_ranking
FROM 
    cte_filtered_table f
        JOIN
    interest_map m ON f.interest_id = m.id
GROUP BY interest_id, interest_name
ORDER BY stddev_percentile_ranking DESC
LIMIT 5;
    
-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?

WITH cte_month_count AS (
    SELECT
        interest_id,
        COUNT(DISTINCT month_year) AS month_count
    FROM interest_metrics
    GROUP BY interest_id
    HAVING month_count < 6),
cte_filtered_table AS (
    SELECT
        *
    FROM interest_metrics
    WHERE interest_id NOT IN (SELECT interest_id FROM cte_month_count)),
cte_top_percentile_ranking AS (
    SELECT
        interest_id,
        interest_name,
        ROUND(STDDEV_SAMP(percentile_ranking), 2) AS stddev_percentile_ranking
    FROM 
        cte_filtered_table f
            JOIN
        interest_map m ON f.interest_id = m.id
    GROUP BY interest_id, interest_name
    ORDER BY stddev_percentile_ranking DESC
    LIMIT 5),
cte_min_max_percentile_ranking AS (
    SELECT
        DISTINCT interest_id,
        MIN(percentile_ranking) OVER (PARTITION BY interest_id) AS min_percentile_ranking,
        MAX(percentile_ranking) OVER (PARTITION BY interest_id) AS max_percentile_ranking
    FROM interest_metrics
    WHERE interest_id IN (SELECT interest_id FROM cte_top_percentile_ranking)),
cte_min_section AS (
    SELECT
        f.interest_id,
        f.month_year AS min_year,
        m.min_percentile_ranking
    FROM
        cte_filtered_table f
            JOIN
        cte_min_max_percentile_ranking m ON f.interest_id = m.interest_id AND f.percentile_ranking = m.min_percentile_ranking),
cte_max_section AS (
    SELECT
        f.interest_id,
        f.month_year AS max_year,
        m.max_percentile_ranking
    FROM
        cte_filtered_table f
            JOIN
        cte_min_max_percentile_ranking m ON f.interest_id = m.interest_id AND f.percentile_ranking = m.max_percentile_ranking)
SELECT 
    a.interest_id,
    c.interest_name,
    a.min_year,
    a.min_percentile_ranking,
    b.max_year,
    b.max_percentile_ranking
FROM
    cte_min_section a
        JOIN
    cte_max_section b ON a.interest_id = b.interest_id
        JOIn
    interest_map c ON a.interest_id = c.id
ORDER BY b.max_percentile_ranking DESC;

-- D. Index Analysis
-- 1. What is the top 10 interests by the average composition for each month?

SELECT * FROM interest_metrics;
WITH cte_average_composition AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value), 2) AS average_composition
    FROM
        interest_metrics a
            JOIN
        interest_map b ON a.interest_id = b.id),
cte_ranking AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        RANK() OVER (PARTITION BY month_year ORDER BY average_composition DESC) AS ranking
    FROM cte_average_composition)
SELECT * FROM cte_ranking
WHERE ranking <= 10 AND month_year IS NOT NULL;

-- 2. For all of these top 10 interests - which interest appears the most often?

WITH cte_average_composition AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value), 2) AS average_composition
    FROM
        interest_metrics a
            JOIN
        interest_map b ON a.interest_id = b.id),
cte_ranking AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        RANK() OVER (PARTITION BY month_year ORDER BY average_composition DESC) AS ranking
    FROM cte_average_composition)
SELECT 
    interest_id,
    interest_name,
    COUNT(interest_id) AS id_count
FROM cte_ranking
WHERE ranking <= 10 AND month_year IS NOT NULL
GROUP BY interest_id, interest_name
ORDER BY id_count DESC;
    
-- 3. What is the average of the average composition for the top 10 interests for each month?

WITH cte_average_composition AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value), 2) AS average_composition
    FROM
        interest_metrics a
            JOIN
        interest_map b ON a.interest_id = b.id),
cte_ranking AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        average_composition,
        RANK() OVER (PARTITION BY month_year ORDER BY average_composition DESC) AS ranking
    FROM cte_average_composition)
SELECT
    month_year,
    ROUND(AVG(average_composition), 2) AS average_average_composition
FROM
    cte_ranking
WHERE ranking <= 10 AND month_year IS NOT NULL
GROUP BY month_year;
	
-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.

WITH cte_average_composition AS (
    SELECT
        month_year,
        interest_id,
        interest_name,
        ROUND((composition / index_value), 2) AS average_composition
    FROM
        interest_metrics a
            JOIN
        interest_map b ON a.interest_id = b.id),
cte_max_index_composition AS (
    SELECT
        DISTINCT month_year,
        MAX(average_composition) OVER (PARTITION BY month_year) AS max_index_composition
    FROM cte_average_composition),
cte_rolling_average AS (
    SELECT
        a.month_year,
        c.interest_name,
        a.max_index_composition,
        ROUND(AVG(a.max_index_composition) OVER (ORDER BY a.month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS 3_month_moving_avg,
        CONCAT(LAG(c.interest_name) OVER (ORDER BY a.month_year), ' : ', LAG(a.max_index_composition) OVER (ORDER BY a.month_year)) AS 1_month_ago,
        CONCAT(LAG(c.interest_name, 2) OVER (ORDER BY a.month_year), ' : ', LAG(a.max_index_composition, 2) OVER (ORDER BY a.month_year)) AS 2_month_ago
    FROM
        cte_max_index_composition a
            JOIN
        cte_average_composition b ON a.month_year = b.month_year
            JOIN
        interest_map c ON b.interest_id = c.id
    WHERE b.average_composition = max_index_composition)
SELECT * 
FROM cte_rolling_average
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01';
	
