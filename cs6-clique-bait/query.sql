-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #6 - Clique Bait

-- 2. Digital Analysis

USE clique_bait;

-- 2.1. How many users are there?

SELECT COUNT(DISTINCT user_id)
FROM users;

-- 2.2. How many cookies does each user have on average?
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

-- 2.3. What is the unique number of visits by all users per month?

SELECT 
	MONTH(event_time) AS event_month,
	COUNT(DISTINCT visit_id) AS number_visits
FROM events
GROUP BY event_month
ORDER BY event_month;

-- 2.4. What is the number of events for each event type?

SELECT
	event_type,
	COUNT(event_time) AS number_events
FROM events
GROUP BY event_type
ORDER BY event_type;

-- 2.5. What is the percentage of visits which have a purchase event?

SELECT 
	COUNT(DISTINCT visit_id) * 100 / (SELECT COUNT(DISTINCT visit_id) FROM events)  AS  purchase_visit_percentage  
FROM 
	events 
		JOIN 
	event_identifier USING (event_type)
WHERE event_name = 'Purchase';

-- 2.6. What is the percentage of visits which view the checkout page but do not have a purchase event?

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
		
-- 2.7. What are the top 3 pages by number of views?

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

-- 2.8. What is the number of views and cart adds for each product category?

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

-- 2.9. What are the top 3 products by purchases?

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

-- 3. Product Funnel Analysis
-- 3.1. Using a single SQL query - create a new output table which has the following details:
   -- How many times was each product viewed?
   -- How many times was each product added to cart?
   -- How many times was each product added to a cart but not purchased (abandoned)?
   -- How many times was each product purchased?

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

-- 3.2. Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

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

-- 3.3.1. Which product had the most views, cart adds and purchases?
-- 3.3.1.1. most views

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

-- 3.3.1.2. most cart adds

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

-- 3.3.1.3. most purchases

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

-- 3.3.2. Which product was most likely to be abandoned?

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

-- 3.3.3. Which product had the highest view to purchase percentage?

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

-- 3.3.4. What is the average conversion rate from view to cart add?

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

-- 3.3.5. What is the average conversion rate from cart add to purchase?

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

-- 4. Campaigns Analysis
-- 4.1. Generate a table that has 1 single row for every unique visit_id record and has the following columns:-- user_id
  -- visit_id
  -- visit_start_time: the earliest event_time for each visit
  -- page_views: count of page views for each visit
  -- cart_adds: count of product cart add events for each visit
  -- purchase: 1/0 flag if a purchase event exists for each visit
  -- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
  -- impression: count of ad impressions for each visit
  -- click: count of ad clicks for each visit
  -- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

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
