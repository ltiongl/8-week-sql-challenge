# [Case Study #6 - Clique Bait](https://8weeksqlchallenge.com/case-study-6/)

## 2. Digital Analysis
Using the available datasets - answer the following questions using a single query for each one:

### 1. How many users are there?
```sql
SELECT COUNT(DISTINCT user_id) AS user_count
FROM users;
```

<img width="99" alt="image" src="https://github.com/user-attachments/assets/09be7a4d-3c4a-4f24-9e79-193f6c39c41d">

### 2. How many cookies does each user have on average?
```sql
-- Method 1

WITH cookies AS (
SELECT 
    user_id,
    COUNT(cookie_id) AS cookie_count
FROM users
GROUP BY user_id)
SELECT
    ROUND(AVG(cookie_count)) AS average_cookies
FROM cookies;

-- Method 2

SELECT
    ROUND(COUNT(cookie_id) / COUNT(DISTINCT user_id)) AS average_cookies
FROM users;
```

<img width="140" alt="image" src="https://github.com/user-attachments/assets/e8a65f0c-8358-4ee1-8ed4-6d87c64d203d">


### 3. What is the unique number of visits by all users per month?
```sql
SELECT 
    MONTH(event_time) AS event_month,
    COUNT(DISTINCT visit_id) AS number_visits
FROM events
GROUP BY event_month
ORDER BY event_month;
```

<img width="225" alt="image" src="https://github.com/user-attachments/assets/6feb7f13-e8aa-4b1a-91d0-0cc64f95a699">

### 4. What is the number of events for each event type?
```sql
SELECT
    event_type,
    COUNT(event_time) AS number_events
FROM events
GROUP BY event_type
ORDER BY event_type;
```

<img width="221" alt="image" src="https://github.com/user-attachments/assets/f38929ed-f882-4b45-8a26-3e1723f7d148">

### 5. What is the percentage of visits which have a purchase event?
```sql
SELECT 
    COUNT(DISTINCT visit_id) * 100 / (SELECT COUNT(DISTINCT visit_id) FROM events)  AS  purchase_visit_percentage  
FROM 
    events 
        JOIN 
    event_identifier USING (event_type)
WHERE event_name = 'Purchase';
```

<img width="210" alt="image" src="https://github.com/user-attachments/assets/d47434ce-c117-4242-93d8-57be309b4899">

### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
```sql
WITH checkout_event AS (
    SELECT
        SUM(CASE WHEN p.page_name = 'Checkout' THEN 1 ELSE 0 END) AS checkout_count,
        SUM(CASE WHEN p.page_name = 'Confirmation' THEN 1 ELSE 0 END) AS confirmation_count
    FROM
        events e
            JOIN
        page_hierarchy p ON e.page_id = p.page_id)
SELECT
    ROUND(((checkout_count - confirmation_count) / checkout_count * 100), 2) AS non_purchase_percentage
FROM checkout_event; 
```

<img width="209" alt="image" src="https://github.com/user-attachments/assets/a8c24068-9f0a-4dda-8f37-a5022a3b7c6a">

### 7. What are the top 3 pages by number of views?
```sql
SELECT
    p.page_name,
    COUNT(e.event_time) AS view_count
FROM
    events e
        JOIN
    page_hierarchy p ON e.page_id = p.page_id
GROUP BY p.page_name
ORDER BY view_count DESC
LIMIT 3;
```

<img width="201" alt="image" src="https://github.com/user-attachments/assets/6b08b231-5d06-4225-a578-6f56a61b5b33">

### 8. What is the number of views and cart adds for each product category?
```sql
SELECT
    p.product_category,
    SUM(CASE WHEN e.event_type = '1' THEN 1 ELSE 0 END) AS view_count,
    SUM(CASE WHEN e.event_type = '2' THEN 1 ELSE 0 END) AS add_cart_count
FROM
    events e
        JOIN
    page_hierarchy p ON e.page_id = p.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category
ORDER BY p.product_category;
```

<img width="365" alt="image" src="https://github.com/user-attachments/assets/2739be11-c5fe-4c61-bf28-c885c924c90f">

### 9. What are the top 3 products by purchases?
```sql
SELECT
    p.page_name,
    SUM(CASE WHEN e.event_type = '2' THEN 1 ELSE 0 END) AS purchase_count
FROM
    events e
        JOIN
    page_hierarchy p ON e.page_id = p.page_id
WHERE p.product_id IS NOT NULL 
GROUP BY p.page_name
ORDER BY purchase_count DESC
LIMIT 3;
```

<img width="257" alt="image" src="https://github.com/user-attachments/assets/ba154e77-53e0-4996-986b-c1a1c9d2c4c6">

## 3. Product Funnel Analysis
### 1. Using a single SQL query - create a new output table which has the following details:

* How many times was each product viewed?
* How many times was each product added to cart?
* How many times was each product added to a cart but not purchased (abandoned)?
* How many times was each product purchased?

```sql
WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase')
SELECT
    page_name,
    COUNT(view_id) AS view_count,
    COUNT(add_cart_id) AS add_cart_count,
    COUNT(add_cart_id) -  COUNT(purchase_id) AS abondon_count,
    COUNT(purchase_id) AS purchase_count
FROM 
    cte_event_visit_id ev
        LEFT JOIN
    cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
GROUP BY page_name;
```

<img width="599" alt="image" src="https://github.com/user-attachments/assets/ad1fb715-1641-491b-96bb-1a27b84b673e">

### 2. Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.
```sql
WITH cte_event_visit_id AS (
    SELECT
        product_category,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase')
SELECT
    product_category,
    COUNT(view_id) AS view_count,
    COUNT(add_cart_id) AS add_cart_count,
    COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
    COUNT(purchase_id) AS purchase_count
FROM 
    cte_event_visit_id ev
        LEFT JOIN
    cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
GROUP BY product_category;
```

<img width="617" alt="image" src="https://github.com/user-attachments/assets/a67e6f07-9ac9-42d7-a82f-9204c156e67a">

### 3. Use your 2 new output tables - answer the following questions:

#### 1. Which product had the most views, cart adds and purchases?
```sql
-- most views

WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
           JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase'),
cte_event_count AS (
    SELECT
        page_name,
        COUNT(view_id) AS view_count,
        COUNT(add_cart_id) AS add_cart_count,
        COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
        COUNT(purchase_id) AS purchase_count
    FROM 
        cte_event_visit_id ev
            LEFT JOIN
        cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
    GROUP BY page_name)
SELECT
    page_name,
    view_count
FROM cte_event_count
ORDER BY view_count
LIMIT 1;
```

<img width="193" alt="image" src="https://github.com/user-attachments/assets/453f14e1-4fe1-4f0f-b4ce-c96586d809cf">

```sql
-- most cart adds

WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase'),
cte_event_count AS (
    SELECT
        page_name,
        COUNT(view_id) AS view_count,
        COUNT(add_cart_id) AS add_cart_count,
        COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
        COUNT(purchase_id) AS purchase_count
    FROM 
        cte_event_visit_id ev
            LEFT JOIN
        cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
    GROUP BY page_name)
SELECT
    page_name,
    add_cart_count
FROM cte_event_count
ORDER BY add_cart_count DESC
LIMIT 1;
```

<img width="227" alt="image" src="https://github.com/user-attachments/assets/9f1f38ce-227a-4f2e-8357-07dfd8b9024e">

```sql
-- most purchases

WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase'),
cte_event_count AS (
    SELECT
        page_name,
        COUNT(view_id) AS view_count,
        COUNT(add_cart_id) AS add_cart_count,
        COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
        COUNT(purchase_id) AS purchase_count
    FROM 
        cte_event_visit_id ev
            LEFT JOIN
        cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
    GROUP BY page_name)
SELECT
    page_name,
    purchase_count
FROM cte_event_count
ORDER BY purchase_count DESC
LIMIT 1;
```

<img width="231" alt="image" src="https://github.com/user-attachments/assets/35773bba-d89c-4e45-83bd-8800aa4fde55">

#### 2. Which product was most likely to be abandoned?
```sql
WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase'),
cte_event_count AS (
    SELECT
        page_name,
        COUNT(view_id) AS view_count,
        COUNT(add_cart_id) AS add_cart_count,
        COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
        COUNT(purchase_id) AS purchase_count
    FROM 
        cte_event_visit_id ev
            LEFT JOIN
        cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
    GROUP BY page_name)
SELECT
    page_name,
    abandon_count
FROM cte_event_count
ORDER BY abandon_count DESC
LIMIT 1;
```

<img width="252" alt="image" src="https://github.com/user-attachments/assets/0c9e2324-7b06-41e7-82b7-2c11dadf6e25">

#### 3. Which product had the highest view to purchase percentage?
```sql
WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase'),
cte_event_count AS (
    SELECT
        page_name,
        COUNT(view_id) AS view_count,
        COUNT(add_cart_id) AS add_cart_count,
        COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
        COUNT(purchase_id) AS purchase_count
    FROM 
        cte_event_visit_id ev
            LEFT JOIN
        cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
    GROUP BY page_name)
SELECT
    page_name,
    ROUND(purchase_count / view_count * 100, 2) AS highest_view_to_purchase_percentage
FROM cte_event_count
ORDER BY highest_view_to_purchase_percentage DESC
LIMIT 1;
```

<img width="393" alt="image" src="https://github.com/user-attachments/assets/a383427a-0196-46fe-837e-01454d4dff8c">

#### 4. What is the average conversion rate from view to cart add?
```sql
WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase'),
cte_event_count AS (
    SELECT
        page_name,
        COUNT(view_id) AS view_count,
        COUNT(add_cart_id) AS add_cart_count,
        COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
        COUNT(purchase_id) AS purchase_count
    FROM 
        cte_event_visit_id ev
            LEFT JOIN
        cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
    GROUP BY page_name)
SELECT
    ROUND(AVG(add_cart_count / view_count) * 100, 2) AS average_conversion_rate_from_view_to_cart_add
FROM cte_event_count;
```

<img width="372" alt="image" src="https://github.com/user-attachments/assets/2006f909-091c-4579-b515-2ed5134f0f77">


#### 5. What is the average conversion rate from cart add to purchase?
```sql
WITH cte_event_visit_id AS (
    SELECT
        page_name,
        CASE WHEN event_name = 'Page View' THEN visit_id END AS view_id,
        CASE WHEN event_name = 'Add to Cart' THEN visit_id END AS add_cart_id
    FROM 
        events
            JOIN
        event_identifier USING (event_type)
            JOIN
        page_hierarchy USING (page_id)
    WHERE product_id IS NOT NULL),
cte_purchase_visit_id AS (
    SELECT
        visit_id AS purchase_id
    FROM 
        events 
            JOIN
        event_identifier USING (event_type)
    WHERE event_name = 'Purchase'),
cte_event_count AS (
    SELECT
        page_name,
        COUNT(view_id) AS view_count,
        COUNT(add_cart_id) AS add_cart_count,
        COUNT(add_cart_id) -  COUNT(purchase_id) AS abandon_count,
        COUNT(purchase_id) AS purchase_count
    FROM 
        cte_event_visit_id ev
            LEFT JOIN
        cte_purchase_visit_id pv ON ev.add_cart_id = pv.purchase_id
    GROUP BY page_name)
SELECT
    ROUND(AVG(purchase_count / add_cart_count) * 100, 2) AS average_conversion_rate_from_cart_add_to_purchase
FROM cte_event_count;
```

<img width="405" alt="image" src="https://github.com/user-attachments/assets/7f39832a-a624-45ed-bba9-13d10d484f7c">

## 4. Campaigns Analysis
Generate a table that has 1 single row for every unique `visit_id` record and has the following columns:

* `user_id`
* `visit_id`
* `visit_start_time`: the earliest `event_time` for each visit
* `page_views`: count of page views for each visit
* `cart_adds`: count of product cart add events for each visit
* `purchase`: 1/0 flag if a purchase event exists for each visit
* `campaign_name`: map the visit to a campaign if the `visit_start_time` falls between the start_date and end_date
* `impression`: count of ad impressions for each visit
* `click`: count of ad clicks for each visit
* (Optional column) `cart_products`: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the `sequence_number`)
Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

Some ideas you might want to investigate further include:

* Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
* Does clicking on an impression lead to higher purchase rates?
* What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
* What metrics can you use to quantify the success or failure of each campaign compared to eachother?

```sql
SELECT
    c.user_id,
    a.visit_id,
    MIN(a.event_time) AS visit_start_time,
    SUM(CASE WHEN b.event_name = 'Page View' THEN 1 ELSE 0 END)  AS page_views,
    SUM(CASE WHEN b.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds,
    SUM(CASE WHEN b.event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
    e.campaign_name,
    SUM(CASE WHEN b.event_name = 'Ad Impression' THEN 1 ELSE 0 END) AS impression,
    SUM(CASE WHEN b.event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
    GROUP_CONCAT((CASE WHEN d.product_id IS NOT NULL AND b.event_name = 'Add to Cart' THEN d.page_name ELSE NULL END) ORDER BY sequence_number SEPARATOR ', ') AS cart_products
FROM 
    events a
        JOIN
    event_identifier b ON a.event_type = b.event_type
        JOIN
    users c ON a.cookie_id = c.cookie_id
        JOIN
    page_hierarchy d ON a.page_id = d.page_id
        LEFT JOIN
    campaign_identifier e ON a.event_time BETWEEN e.start_date AND e.end_date
GROUP BY c.user_id, a.visit_id, e.campaign_name;
```

<img width="1503" alt="image" src="https://github.com/user-attachments/assets/c96c803b-b79e-4479-9d4e-22d3345b45c3">

The is just a part of the table. There is a total of 3564 rows in the table.
