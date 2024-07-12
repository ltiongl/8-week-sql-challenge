# [Case Study #8 - Fresh Segments](https://8weeksqlchallenge.com/case-study-8/)

## Data Exploration and Cleansing

### 1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month
```sql
DESCRIBE interest_metrics;

ALTER TABLE interest_metrics
DROP COLUMN month_year;

ALTER TABLE interest_metrics
ADD COLUMN month_year DATE AFTER `_year`;

UPDATE interest_metrics
SET month_year = DATE(CONCAT(_year, '-', _month, '-01'));

SELECT * FROM interest_metrics;
```

<img width="725" alt="image" src="https://github.com/user-attachments/assets/71bee442-41d8-4de3-a602-4b06e4ca72f1">

The is just a part of the table. There is a total of 14273 rows in the table.

### 2. What is count of records in the `fresh_segments.interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?
```sql
SELECT 
    month_year,
    COUNT(*) AS record_count
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;
```

<img width="212" alt="image" src="https://github.com/user-attachments/assets/c5e14215-99dd-4422-af7a-581cede684c9">

### 3. What do you think we should do with these null values in the `fresh_segments.interest_metrics`
```sql
DELETE FROM interest_metrics
WHERE interest_id IS NULL;

SELECT * FROM interest_metrics;
```

<img width="725" alt="image" src="https://github.com/user-attachments/assets/126c3dcc-61d7-4bd3-bbf0-601fc5279ea1">

The is just a part of the table. There is a total of 13080 rows in the table.

### 4. How many interest_id values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?
```sql
SELECT
    COUNT(DISTINCT interest_id) AS not_in_map
FROM interest_metrics 
WHERE interest_id NOT IN (SELECT id FROM interest_map);
```

<img width="102" alt="image" src="https://github.com/user-attachments/assets/3b9c5665-b47e-4ecc-9c51-a0744a6f9f02">

```sql
SELECT
    COUNT(DISTINCT id) AS not_in_metrics
FROM interest_map 
WHERE id NOT IN (SELECT interest_id FROM interest_metrics);
```

<img width="125" alt="image" src="https://github.com/user-attachments/assets/02df4222-f4f1-45d7-82b3-36f4fd51ede2">

### 5. Summarise the id values in the `fresh_segments.interest_map` by its total record count in this table
```sql
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
```

<img width="482" alt="image" src="https://github.com/user-attachments/assets/edc68ff9-6d58-45d1-9967-2af676990964">

The is just a part of the table. There is a total of 1202 rows in the table.

### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id` = 21246 in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the id column.
```sql
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
```

<img width="1665" alt="image" src="https://github.com/user-attachments/assets/e29da60b-57a2-4778-abf9-c083f89102d2">

### 7. Are there any records in your joined table where the `month_year` value is before the `created_at` value from the `fresh_segments.interest_map` table? Do you think these values are valid and why?
```sql
SELECT
    month_year,
    created_at
FROM
    interest_metrics a 
        JOIN
    interest_map b ON a.interest_id = b.id
WHERE month_year < created_at;
```

<img width="258" alt="image" src="https://github.com/user-attachments/assets/abcd2f71-cc3d-40e9-951e-725769df7864">

## Interest Analysis

### 1. Which interests have been present in all `month_year` dates in our dataset?
```sql
SELECT
    COUNT(DISTINCT month_year) AS month_year_count
FROM interest_metrics;
```

<img width="467" alt="image" src="https://github.com/user-attachments/assets/0f061435-f85a-47c8-a312-b70453140fde">

The is just a part of the table. There is a total of 480 rows in the table.

### 2. Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?
```sql
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
```

<img width="369" alt="image" src="https://github.com/user-attachments/assets/75f9dbe8-a701-427c-be50-71746a1ede95">

### 3. If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?
```sql
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
```

<img width="156" alt="image" src="https://github.com/user-attachments/assets/614f60bf-6c0f-4fc8-ab7a-8eddd9b5f2e5">

### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
```sql
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
```

<img width="549" alt="image" src="https://github.com/user-attachments/assets/dcddd9e3-d0b4-4ec9-9095-2bb4c1b910b8">

Removed_percentage is not significant, the data points can be removed.

### 5. After removing these interests - how many unique interests are there for each month?
```sql
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
```

<img width="236" alt="image" src="https://github.com/user-attachments/assets/e5534225-f2ef-4887-b6de-07ad69e684d4">

## Segment Analysis

### 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
```sql
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
```

<img width="350" alt="image" src="https://github.com/user-attachments/assets/9405884d-2830-4e01-bba9-379c7741c376">

```sql
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
```

<img width="2378 alt="image" src="https://github.com/user-attachments/assets/348565cd-8ab8-4a2a-ab7c-2a3ea24f3d91">

### 2. Which 5 interests had the lowest average ranking value?
```sql
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
```

<img width="438" alt="image" src="https://github.com/user-attachments/assets/82d78089-efda-46ef-9b4b-4940933a336f">

### 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
```sql
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
```

<img width="576" alt="image" src="https://github.com/user-attachments/assets/2dbab6e1-4ee6-437e-a455-519736cbace9">

### 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
```sql
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
```

<img width="921" alt="image" src="https://github.com/user-attachments/assets/c053b02e-9751-424b-9029-f1ab6d939546">

## Index Analysis

The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

### 1. What is the top 10 interests by the average composition for each month?
```sql
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
```

<img width="638" alt="image" src="https://github.com/user-attachments/assets/6371c1f3-d9f7-495e-a9e7-a35e064a5b0d">

The is just a part of the table. There is a total of 142 rows in the table.

### 2. For all of these top 10 interests - which interest appears the most often?
```sql
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
```

<img width="548" alt="image" src="https://github.com/user-attachments/assets/854a2cfd-b248-48c3-8732-7dc4c901602a">

### 3. What is the average of the average composition for the top 10 interests for each month?
```sql
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
```

<img width="336" alt="image" src="https://github.com/user-attachments/assets/37ac0fa6-0209-4eb2-9e63-9a5faedcc8ea">

### 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
```sql
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
```

<img width="1205" alt="image" src="https://github.com/user-attachments/assets/5969808a-b79f-489f-859d-3baa1cc44f2c">
