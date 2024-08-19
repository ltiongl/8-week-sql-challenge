-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #1 - Danny's Diner

USE dannys_diner;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
    customer_id,
    SUM(price) AS total_amount_spent
FROM 
    sales 
        JOIN
    menu USING (product_id)
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS num_days
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH cte_first_item AS (
    SELECT 
        customer_id,
        product_id,
        product_name,
        order_date,
        DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranking
    FROM 
        sales 
            JOIN
        menu USING (product_id))
SELECT 
    customer_id,
    product_name,
    order_date
FROM cte_first_item
WHERE ranking = 1
GROUP BY customer_id, product_name, order_date;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
    product_name,
    COUNT(order_date) AS purchase_count
FROM
    menu 
        JOIN
    sales USING (product_id)
GROUP BY product_name
ORDER BY purchase_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH cte_popular_items AS (
    SELECT
        customer_id,
        product_name,
        COUNT(order_date) AS order_count,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) AS ranking
    FROM
        sales 
            JOIN
        menu USING (product_id)
    GROUP BY customer_id, product_name)
SELECT
    customer_id,
    product_name,
    order_count
FROM cte_popular_items
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH cte_first_purchase AS (
    SELECT
        customer_id,
        product_name,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS ranking
    FROM
        sales 
            JOIN
        menu USING (product_id)
            JOIN
        members USING (customer_id)
    WHERE order_date >= join_date)
SELECT 
    customer_id,
    product_name
FROM cte_first_purchase
WHERE ranking = 1;
    
-- 7. Which item was purchased just before the customer became a member?

WITH cte_purchase_before_member AS (
    SELECT
        customer_id,
        product_name,
        DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS ranking
    FROM
        sales
            JOIN
        menu USING (product_id)
            JOIN
        members USING (customer_id)
    WHERE order_date < join_date)
SELECT 
    customer_id,
    product_name
FROM cte_purchase_before_member
WHERE ranking = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
    customer_id,
    COUNT(product_id) AS item_count,
    SUM(price) AS total_spent
FROM
    sales 
        JOIN
    menu USING (product_id)
        JOIN
    members USING (customer_id)
WHERE order_date < join_date
GROUP BY customer_id
ORDER BY customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH cte_points AS (
    SELECT
        customer_id,
        CASE WHEN product_name = "sushi" THEN price * 10 * 2 ELSE price * 10 END AS points
    FROM
        sales
            JOIN
        menu USING (product_id))
SELECT
    customer_id,
    SUM(points) AS total_points
FROM cte_points
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte_points AS (
    SELECT
        customer_id,
        CASE WHEN ((order_date - join_date) BETWEEN 0 AND 6) OR product_name = "sushi" THEN price * 10 * 2 ELSE price * 10 END AS points
    FROM
        sales 
            JOIN
        menu USING (product_id)
            JOIN
        members USING (customer_id)
    WHERE MONTH(order_date) = '01')
SELECT
    customer_id,
    SUM(points) AS total_points
FROM cte_points
WHERE customer_id = 'A' OR customer_id = 'B'
GROUP BY customer_id
ORDER BY customer_id;

-- Bonus Questions
-- 1. Join all the things

SELECT
    customer_id,
    order_date,
    product_name,
    price,
    CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS member
FROM 
    sales 
        JOIN
    menu USING (product_id)
        LEFT JOIN
    members USING (customer_id)
ORDER BY customer_id, order_date, price DESC;

-- 2. Rank all the things

WITH cte_rank_all AS (
    SELECT
        customer_id,
        order_date,
        product_name,
        price,
        CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS member
    FROM 
        sales 
            JOIN
        menu USING (product_id)
            LEFT JOIN
        members USING (customer_id)
    ORDER BY customer_id, order_date, price DESC)
SELECT
    customer_id,
    order_date,
    product_name,
    price,
    CASE WHEN member = 'Y' THEN DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) ELSE NULL END AS ranking
FROM cte_rank_all;
