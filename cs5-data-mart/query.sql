-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #5 - Data Mart

-- 1. Data Cleansing Steps

USE data_mart;

DESCRIBE weekly_sales;
SELECT * FROM weekly_sales;

DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales (
    week_date DATE, 
    week_number INT,
    month_number INT,
    calendar_year INT,
    region VARCHAR(13), 
    platform VARCHAR(7), 
    segment VARCHAR(10), 
    age_band VARCHAR(20),
    demographic VARCHAR(20),
    customer_type VARCHAR(8), 
    transactions INT, 
    sales INT,
    avg_transaction FLOAT
);

INSERT INTO clean_weekly_sales
SELECT
    STR_TO_DATE(week_date, '%d/%m/%Y') AS week_date,
    WEEK(STR_TO_DATE(week_date, '%d/%m/%Y')) AS week_number,
    MONTH(STR_TO_DATE(week_date, '%d/%m/%Y')) AS month_number,
    YEAR(STR_TO_DATE(week_date, '%d/%m/%Y')) AS calendar_year,
    region,
    platform,
    CASE
        WHEN segment = 'null' THEN 'unknown' 
        WHEN segment = 'F1' THEN 'F1'
        WHEN segment = 'F2' THEN 'F2'
        WHEN segment = 'F3' THEN 'F3'
        WHEN segment = 'C1' THEN 'C1'
        WHEN segment = 'C2' THEN 'C2'
        WHEN segment = 'C3' THEN 'C3'
        WHEN segment = 'C4' THEN 'C4' END AS segment,
    CASE
        WHEN segment LIKE '%1' THEN 'Young Adults'
        WHEN segment LIKE '%2' THEN 'Middle Aged'
        WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees' 
        ELSE 'unknown' END AS age_band,
    CASE
        WHEN segment LIKE 'C%' THEN 'Couples'
        WHEN segment LIKE 'F%' THEN 'Families' 
        ELSE 'unknown' END AS demographic,
    customer_type,
    transactions,
    sales,
    ROUND((sales / transactions), 2) AS avg_sales
FROM
    weekly_sales;

SELECT * FROM clean_weekly_sales;

-- 2. Data Exploration
-- 2.1. What day of the week is used for each week_date value?

SELECT DISTINCT DAYNAME(week_date) AS day_of_week
FROM clean_weekly_sales;

-- 2.2. What range of week numbers are missing from the dataset?

WITH RECURSIVE week_seq AS (
    SELECT 1 AS seq
        UNION ALL 
    SELECT seq + 1 
    FROM week_seq 
    WHERE seq <= 53)
SELECT seq 
FROM week_seq 
WHERE seq NOT IN (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales);

-- 2.3. How many total transactions were there for each year in the dataset?

SELECT
    calendar_year,
    SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
	
-- 2.4. What is the total sales for each region for each month?

SELECT
    region,
    month_number,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, month_number
ORDER BY month_number, region;
    
-- 2.5. What is the total count of transactions for each platform

SELECT
    platform,
    SUM(transactions) AS total_transaction
FROM clean_weekly_sales
GROUP BY platform
ORDER BY total_transaction DESC;

-- 2.6. What is the percentage of sales for Retail vs Shopify for each month?

WITH sales_per_month AS (
    SELECT 
        calendar_year,
        month_number,
        platform,
        SUM(sales) AS monthly_sales
    FROM clean_weekly_sales 
    GROUP BY calendar_year, month_number, platform)
SELECT
    calendar_year,
    month_number,
    ROUND((SUM(CASE WHEN platform = 'Retail' THEN monthly_sales ELSE NULL END) / SUM(monthly_sales) * 100), 2) AS retail_percentage,
    ROUND((SUM(CASE WHEN platform = 'Shopify' THEN monthly_sales ELSE NULL END) / SUM(monthly_sales) * 100), 2) AS shopify_percentage
FROM sales_per_month
GROUP BY calendar_year, month_number
ORDER BY calendar_year, month_number;
        
-- 2.7. What is the percentage of sales by demographic for each year in the dataset?

WITH sales_per_year AS (
    SELECT
        calendar_year,
        demographic,
        SUM(sales) AS annual_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year, demographic
    ORDER BY calendar_year, demographic)
SELECT
    calendar_year,
    ROUND((SUM(CASE WHEN demographic = 'Couples' THEN annual_sales ELSE NULL END) / SUM(annual_sales) * 100), 2) AS couples_percentage,
    ROUND((SUM(CASE WHEN demographic = 'Families' THEN annual_sales ELSE NULL END) / SUM(annual_sales) * 100), 2) AS families_percentage,
    ROUND((SUM(CASE WHEN demographic = 'unknown' THEN annual_sales ELSE NULL END) / SUM(annual_sales) * 100), 2) AS unknown_percentage
FROM sales_per_year
GROUP BY calendar_year
ORDER BY calendar_year;

-- 2.8. Which age_band and demographic values contribute the most to Retail sales?

SELECT
    age_band,
    demographic,
    SUM(sales) AS total_sales
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_sales DESC;

-- 2.9.Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

SELECT
    calendar_year,
    platform,
    ROUND(AVG(avg_transaction), 2) AS average_avg_transaction,
    ROUND(SUM(sales) / SUM(transactions), 2) AS actual_avg_transaction
FROM clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;

-- 3. Before & After Analysis
-- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
-- Using this analysis approach - answer the following questions:
-- 3.1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

SET @baseline_week = (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales 
    WHERE week_date = '2020-06-15');

WITH cte_sales AS (
    SELECT
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 4 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 3 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    WHERE calendar_year = 2020)
SELECT
    *,
    total_sales_after - total_sales_before AS sales_changes_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_changes_percentage
FROM cte_sales;
    
-- 3.2. What about the entire 12 weeks before and after?

WITH cte_sales AS (
    SELECT
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 12 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 11 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    WHERE calendar_year = 2020)
SELECT
    *,
    total_sales_after - total_sales_before AS sales_changes_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_changes_percentage
FROM cte_sales;

-- 3.3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- For 4 weeks comparison

WITH cte_sales AS (
    SELECT
        calendar_year,
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 4 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 3 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    GROUP BY calendar_year)
SELECT
    *,
    total_sales_after - total_sales_before AS sales_change_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_change_percentage
FROM cte_sales
ORDER BY calendar_year;

-- For 12 weeks comparison

WITH cte_sales AS (
    SELECT
        calendar_year,
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 12 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 11 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    GROUP BY calendar_year)
SELECT
    *,
    total_sales_after - total_sales_before AS sales_change_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_change_percentage
FROM cte_sales
ORDER BY calendar_year;

-- 4. Bonus Question
-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
  -- region
  -- platform
  -- age_band
  -- demographic
  -- customer_type

SET @baseline_week = (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales 
    WHERE week_date = '2020-06-15');

-- region

WITH cte_sales AS (
    SELECT
        region,
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 12 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 11 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY region)
SELECT
    region,
    total_sales_after - total_sales_before AS sales_change_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_change_percentage
FROM cte_sales
ORDER BY sales_change_percentage
LIMIT 1;

-- platform

WITH cte_sales AS (
    SELECT
        platform,
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 12 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 11 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY platform)
SELECT
    platform,
    total_sales_after - total_sales_before AS sales_change_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_change_percentage
FROM cte_sales
ORDER BY sales_change_percentage
LIMIT 1;

-- age_band

WITH cte_sales AS (
    SELECT
        age_band,
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 12 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 11 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    WHERE calendar_year = 2020 AND age_band != 'Unknown'
    GROUP BY age_band)
SELECT
    age_band,
    total_sales_after - total_sales_before AS sales_change_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_change_percentage
FROM cte_sales
ORDER BY sales_change_percentage
LIMIT 1;

-- demographic

WITH cte_sales AS (
    SELECT
        demographic,
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 12 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 11 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    WHERE calendar_year = 2020 AND demographic != 'Unknown'
    GROUP BY demographic)
SELECT
    demographic,
    total_sales_after - total_sales_before AS sales_change_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_change_percentage
FROM cte_sales
ORDER BY sales_change_percentage
LIMIT 1;

-- customer_type

WITH cte_sales AS (
    SELECT
        customer_type,
        SUM(CASE WHEN week_number BETWEEN @baseline_week - 12 AND  @baseline_week - 1 THEN sales END) AS total_sales_before,
        SUM(CASE WHEN week_number BETWEEN @baseline_week AND  @baseline_week + 11 THEN sales END) AS total_sales_after
    FROM clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY customer_type)
SELECT
    customer_type,
    total_sales_after - total_sales_before AS sales_change_value,
    ROUND((total_sales_after - total_sales_before) / total_sales_before * 100, 2) AS sales_change_percentage
FROM cte_sales
ORDER BY sales_change_percentage
LIMIT 1;
