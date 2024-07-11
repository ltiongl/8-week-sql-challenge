# [Case Study #1 - Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)

## Case Study Questions

### 1. What is the total amount each customer spent at the restaurant?

```mysql
SELECT 
    customer_id,
    SUM(price) AS total_amount_spent
FROM 
    sales 
        JOIN
    menu USING (product_id)
GROUP BY customer_id;
```

<img width="263" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/b9f7a691-ddbd-4ee3-b394-38cc3aa7f7f1">

### 2. How many days has each customer visited the restaurant?

```sql
SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS num_days
FROM sales
GROUP BY customer_id;
```

<img width="194" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/f01dee6f-b4e4-43b7-92e6-e0bb8a157dc2">

### 3. What was the first item from the menu purchased by each customer?

```sql
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
```

<img width="316" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/b7ebeb5d-1a13-498d-9bee-0065f37d574e">

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
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
```

<img width="254" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/243c6d3d-0c34-48bb-82ba-64f9e4f74f27">

### 5. Which item was the most popular for each customer?

```sql
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
```

<img width="326" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/a7f4f437-5ed6-41c0-9df6-15334b66d81d">

### 6. Which item was purchased first by the customer after they became a member?

```sql
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
```

<img width="225" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/29fdeb31-51cf-4813-b258-b0752ea68364">

### 7. Which item was purchased just before the customer became a member?

```sql
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
```

<img width="225" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/e7775f24-8bbb-46c9-a968-4844091a3c4e">

### 8. What is the total items and amount spent for each member before they became a member?

```sql
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
```

<img width="294" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/9d44632f-03a7-4b50-9d6f-d66cb0ee1993">

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
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
```

<img width="206" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/6cec97ae-837d-4916-bb16-94c00ea66a43">

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

```sql
WITH cte_points AS (
    SELECT
        customer_id,
        CASE
            WHEN ((order_date - join_date) BETWEEN 0 AND 6) OR product_name = "sushi" THEN price * 10 * 2
            ELSE price * 10 END AS points
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
```

<img width="204" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/e48f7f97-7a1a-493e-b58c-68f564ccce9f">

## Bonus Questions

### Join All The Things

```sql
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
    members b USING (customer_id)
ORDER BY customer_id, order_date, price DESC;
```

<img width="488" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/b8d00f3c-3812-4ce7-8749-7c64ecd0a7b7">

### Rank All The Things

```sql
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
    CASE
        WHEN member = 'Y' THEN DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
        ELSE NULL END AS ranking
FROM cte_rank_all;
```

<img width="434" alt="image" src="https://github.com/ltiongl/8-week-sql-challenge/assets/73985806/bdda1e08-e611-46d2-8189-e9f9d83dc457">
