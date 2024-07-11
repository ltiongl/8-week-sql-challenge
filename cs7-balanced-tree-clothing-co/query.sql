-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #7 - Balanced Tree Clothing Co.

USE balanced_tree;

-- A. High Level Sales Analysis
-- 1. What was the total quantity sold for all products?
-- Method 1

SELECT SUM(qty) AS total_quantity_sold
FROM sales;

-- Method 2

SELECT 
    p.product_name,
    SUM(qty) AS total_quantity_sold
FROM 
    product_details p
        JOIN
    sales s ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY total_quantity_sold DESC;
    
-- 2. What is the total generated revenue for all products before discounts?
-- Method 1

SELECT SUM(qty * price) AS total_revenue
FROM sales
ORDER BY total_revenue;

-- Method 2

SELECT
    p.product_name,
    SUM(s.qty * s.price) AS total_revenue
FROM 
    product_details p
        JOIN
    sales s ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- 3. What was the total discount amount for all products?
-- Method 1

SELECT ROUND(SUM(qty * price * discount / 100), 2) AS total_discount
FROM sales
ORDER BY total_discount;

-- Method 2

SELECT
    p.product_name,
    ROUND(SUM(s.qty * s.price * s.discount / 100), 2) AS total_discount
FROM 
    product_details p
        JOIN
    sales s ON p.product_id = s.prod_id
GROUP BY p.product_name
ORDER BY total_discount DESC;

-- B. Transaction Analysis
-- 1. How many unique transactions were there?

SELECT
    COUNT(DISTINCT txn_id) AS unique_txn
FROM sales;

-- 2. What is the average unique products purchased in each transaction?

WITH product_count_per_txn AS (
    SELECT
        txn_id,
        COUNT(DISTINCT prod_id) AS total_product
    FROM sales
    GROUP BY txn_id)
SELECT
    ROUND(AVG(total_product)) AS average_product_per_txn
FROM product_count_per_txn;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

WITH cte_revenue AS (
    SELECT 
        txn_id, 
        SUM(price * qty) AS revenue
    FROM sales
    GROUP BY txn_id),
cte_percentile AS (
    SELECT 
        revenue,
        PERCENT_RANK() OVER (ORDER BY revenue) AS percentile
    FROM cte_revenue)
SELECT
    DISTINCT
    FIRST_VALUE(revenue) OVER (ORDER BY CASE WHEN percentile <= 0.25 THEN percentile END) AS percentile_25,
    FIRST_VALUE(revenue) OVER (ORDER BY CASE WHEN percentile <= 0.50 THEN percentile END) AS percentile_50,
    FIRST_VALUE(revenue) OVER (ORDER BY CASE WHEN percentile <= 0.75 THEN percentile END) AS percentile_75
FROM cte_percentile;

-- 4. What is the average discount value per transaction?

WITH discount_per_txn AS (
    SELECT
        txn_id,
        ROUND(SUM(qty * price * discount / 100)) AS total_txn_discount
    FROM sales
    GROUP BY txn_id)
SELECT
    ROUND(AVG(total_txn_discount), 2)
FROM discount_per_txn;

-- 5. What is the percentage split of all transactions for members vs non-members?

SELECT
    ROUND(COUNT(DISTINCT CASE WHEN member = 1 THEN txn_id END) / COUNT(DISTINCT txn_id) * 100, 2) AS member_percentage,
    ROUND(COUNT(DISTINCT CASE WHEN member = 0 THEN txn_id END) / COUNT(DISTINCT txn_id) * 100, 2) AS non_member_percentage
FROM sales;

-- 6. What is the average revenue for member transactions and non-member transactions?

SELECT
    ROUND(SUM(CASE WHEN member = 1 THEN qty * price END) / (COUNT(DISTINCT CASE WHEN member = 1 THEN txn_id END)), 2) AS average_member_txn,
    ROUND(SUM(CASE WHEN member = 0 THEN qty * price END) / (COUNT(DISTINCT CASE WHEN member = 0 THEN txn_id END)), 2) AS average_non_member_txn
FROM sales;

WITH member_revenue AS (
    SELECT
        member,
        txn_id,
        SUM(price * qty) AS revenue
    FROM sales
    GROUP BY member, txn_id)
SELECT
    member,
    ROUND(AVG(revenue), 2) AS avg_revenue
FROM member_revenue
GROUP BY member;

-- C. Product Analysis
-- 1. What are the top 3 products by total revenue before discount?

SELECT
    s.prod_id,
    p.product_name,
    SUM(s.qty * s.price) AS total_revenue
FROM
    sales s
        JOIN
    product_details p ON s.prod_id = p.product_id
GROUP BY s.prod_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?

SELECT
    p.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    SUM(ROUND((s.qty * s.price * s.discount / 100), 2)) AS total_discount
FROM
    sales s
        JOIN
    product_details p ON s.prod_id = p.product_id
GROUP BY p.segment_name
ORDER BY total_quantity DESC;

-- 3. What is the top selling product for each segment?

WITH cte_selling_ranking AS (
    SELECT
        p.segment_name,
        p.product_name,
        SUM(s.qty) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY p.segment_name ORDER BY SUM(s.qty) DESC) AS product_selling_ranking
    FROM
        sales s
            JOIN
        product_details p ON s.prod_id = p.product_id
    GROUP BY p.segment_name, p.product_name)
SELECT
    segment_name,
    product_name,
    total_quantity
FROM cte_selling_ranking
WHERE product_selling_ranking = 1;

-- 4. What is the total quantity, revenue and discount for each category?

SELECT
    p.category_name,
    SUM(qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    SUM(ROUND((s.qty * s.price * s.discount / 100), 2)) AS total_discount
FROM
    sales s
        JOIN
    product_details p ON s.prod_id = p.product_id
GROUP BY p.category_name;

-- 5. What is the top selling product for each category?

WITH cte_selling_ranking AS (
    SELECT
        p.category_name,
        p.product_name,
        SUM(qty) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY p.category_name ORDER BY SUM(qty) DESC) AS product_selling_ranking
    FROM
        sales s
            JOIN
        product_details p ON s.prod_id = p.product_id
    GROUP BY p.category_name, p.product_name)
SELECT
    category_name,
    product_name,
    total_quantity
FROM cte_selling_ranking
WHERE product_selling_ranking = 1;

-- 6. What is the percentage split of revenue by product for each segment?

WITH cte_revenue AS (
    SELECT
        p.segment_name,
        p.product_name,
        SUM(s.qty * s.price) AS product_revenue
    FROM
        sales s
            JOIN
        product_details p ON s.prod_id = p.product_id
    GROUP BY segment_name, product_name)
SELECT
    segment_name,
    product_name,
    ROUND(product_revenue * 100 / SUM(product_revenue) OVER (PARTITION BY segment_name), 2) AS product_percentage_per_segment
FROM cte_revenue
ORDER BY segment_name, product_percentage_per_segment DESC;
        
-- 7. What is the percentage split of revenue by segment for each category?

WITH cte_revenue AS (
    SELECT
        p.category_name,
        p.segment_name,
        SUM(s.qty * s.price) AS segment_revenue
    FROM
        sales s
            JOIN
        product_details p ON s.prod_id = p.product_id
    GROUP BY category_name, segment_name)
SELECT
    category_name,
    segment_name,
    ROUND(segment_revenue * 100 / SUM(segment_revenue) OVER (PARTITION BY category_name), 2) AS segment_percentage_per_category
FROM cte_revenue
ORDER BY segment_name, segment_percentage_per_category DESC;

-- 8. What is the percentage split of total revenue by category?

WITH cte_revenue AS (
    SELECT
        p.category_name,
        SUM(s.qty * s.price) AS category_revenue
    FROM
        sales s
            JOIN
        product_details p ON s.prod_id = p.product_id
    GROUP BY category_name)
SELECT
    category_name,
    ROUND(category_revenue / SUM(category_revenue) OVER () * 100, 2) AS category_percentage
FROM cte_revenue
ORDER BY category_percentage DESC;

-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

SELECT
    p.product_name,
    ROUND(COUNT(DISTINCT s.txn_id) / (SELECT COUNT(DISTINCT txn_id) FROM sales) * 100, 2) AS penetration
FROM
    sales s
        JOIN
    product_details p ON s.prod_id = p.product_id
WHERE s.qty >= 1
GROUP BY p.product_name
ORDER BY penetration DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WITH cte_txn_product_count AS (
    SELECT
        s.txn_id,
        p.product_id,
        p.product_name,
        s.qty,
        COUNT(p.product_id) OVER (PARTITION BY txn_id) AS product_count
    FROM
        sales s
            JOIN
        product_details p ON s.prod_id = p.product_id),
cte_product_set AS (
    SELECT
        GROUP_CONCAT(product_name ORDER BY product_id SEPARATOR ' , ') AS product_set
    FROM cte_txn_product_count
    WHERE product_count = 3
    GROUP BY txn_id),
cte_set_count AS (
    SELECT
        product_set,
        COUNT(*) AS set_count
    FROM cte_product_set
    GROUP BY product_set)
SELECT 
    product_set,
    set_count
FROM cte_set_count
WHERE set_count = (SELECT MAX(set_count) FROM cte_set_count);

-- D. Bonus Challenge

WITH cte_category AS (
    SELECT
        id AS category_id,
        level_text AS category_name
    FROM product_hierarchy
    WHERE level_name = 'Category'),
cte_segment AS (
    SELECT
        id AS segment_id,
        parent_id AS category_id,
        level_text AS segment_name
    FROM product_hierarchy
    WHERE level_name = 'Segment'),
cte_style AS (
    SELECT
        id AS style_id,
        parent_id AS segment_id,
        level_text AS style_name
    FROM product_hierarchy
    WHERE level_name = 'Style'),
cte_combine AS (
    SELECT 
        a.category_id,
        a.category_name,
        b.segment_id,
        b.segment_name,
        c.style_id,
        c.style_name
    FROM 
        cte_category a
            JOIN
        cte_segment b ON a.category_id = b.category_id
            JOIN
        cte_style c ON b.segment_id = c.segment_id)
SELECT
    product_id,
    price,
    CONCAT(style_name, ' ', segment_name, ' - ', category_name) AS product_name,
    category_id,
    segment_id,
    style_id, 
    category_name,
    segment_name,
    style_name
FROM 
    cte_combine c
        JOIN
    product_prices p ON c.style_id = p.id;
