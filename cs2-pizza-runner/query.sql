-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #2 - Pizza Runner

USE pizza_runner;

-- A. Pizza Metrics
-- A.1. How many pizzas were ordered?

SELECT 
    COUNT(order_id) AS pizza_order_count
FROM customer_orders_updated;

-- A.2. How many unique customer orders were made?

SELECT 
    COUNT(DISTINCT order_id) AS unique_customer_order_count
FROM
    customer_orders_updated;

-- A.3. How many successful orders were delivered by each runner?

SELECT 
    runner_id,
    COUNT(order_id) AS successful_delivery
FROM runner_orders_updated
WHERE distance IS NOT NULL
GROUP BY runner_id;

-- A.4. How many of each type of pizza was delivered?

SELECT
    pizza_name,
    COUNT(order_id) AS delivered_pizza
FROM
    customer_orders_updated 
        JOIN
    runner_orders_updated USING (order_id)
        JOIN
    pizza_names USING (pizza_id)
WHERE distance IS NOT NULL
GROUP BY pizza_name;

-- A.5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT
    customer_id,
    SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS Meatlovers,
    SUM(CASE WHEN pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS Vegetarian
FROM
    customer_orders_updated
        JOIN
    pizza_names USING (pizza_id)
GROUP BY customer_id
ORDER BY customer_id;

-- A.6. What was the maximum number of pizzas delivered in a single order?

SELECT
    order_id,
    COUNT(pizza_id) AS pizza_count
FROM 
    customer_orders_updated 
        JOIN
    runner_orders_updated USING (order_id)
WHERE distance IS NOT NULL
GROUP BY order_id
ORDER BY pizza_count DESC
LIMIT 1;
    
-- A.7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT
    customer_id,
    SUM(CASE WHEN exclusions != '' OR extras != '' THEN 1 ELSE 0 END) AS pizza_count_with_changes,
    SUM(CASE WHEN exclusions = '' AND extras = '' THEN 1 ELSE 0 END) AS pizza_count_no_change
FROM
    customer_orders_updated 
        JOIN
    runner_orders_updated USING (order_id)
WHERE distance IS NOT NULL
GROUP BY customer_id
ORDER BY customer_id;

-- A.8. How many pizzas were delivered that had both exclusions and extras?

SELECT
    COUNT(pizza_id) AS pizza_count
FROM
    customer_orders_updated
        JOIN
    runner_orders_updated USING (order_id)
WHERE distance IS NOT NULL AND (exclusions != '' AND extras != '')
GROUP BY customer_id
ORDER BY customer_id;

-- A.9. What was the total volume of pizzas ordered for each hour of the day?

SELECT
    HOUR(order_time) AS hour,
    COUNT(order_id) AS pizza_count
FROM customer_orders_updated
GROUP BY hour
ORDER BY hour;
    
-- A.10. What was the volume of orders for each day of the week?

SELECT
    DAYNAME(order_time) AS day,
    COUNT(order_id) AS order_count
FROM customer_orders_updated
GROUP BY day;
    
-- B. Runner and Customer Experience
-- B.1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT
    WEEK(registration_date) AS week,
    COUNT(runner_id) AS runner_count
FROM runners
GROUP BY week;

-- B.2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT
    runner_id,
    ROUND(AVG(MINUTE(TIMEDIFF(pickup_time, order_time))), 2) AS average_time_in_min
FROM
    runner_orders_updated
        JOIN
    customer_orders_updated USING (order_id)
GROUP BY runner_id;

-- B.3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
    
WITH pizza_preparation_time AS (
    SELECT
        COUNT(pizza_id) AS pizza_count,
        MINUTE(TIMEDIFF(pickup_time, order_time)) AS prepare_time_in_min
    FROM	
        runner_orders_updated
            JOIN
        customer_orders_updated USING (order_id)
    GROUP BY order_id, prepare_time_in_min)
SELECT
    pizza_count,
    ROUND(AVG(prepare_time_in_min), 2) AS average_prepare_time_in_min
FROM pizza_preparation_time
GROUP BY pizza_count;

-- B.4. What was the average distance travelled for each customer?

SELECT
    customer_id,
    ROUND(AVG(distance), 2) AS average_distance
FROM
    customer_orders_updated 
        JOIN
    runner_orders_updated USING (order_id)
GROUP BY customer_id
ORDER BY customer_id;

-- B.5. What was the difference between the longest and shortest delivery times for all orders?

SELECT
    (MAX(duration) - MIN(duration)) AS diff_delivery_time
FROM runner_orders_updated;

-- B.6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT
    runner_id,
    order_id,
    ROUND(AVG(distance / (duration / 60)), 2) AS average_speed
FROM runner_orders_updated
WHERE distance IS NOT NULL
GROUP BY runner_id, order_id
ORDER BY runner_id;

-- B.7. What is the successful delivery percentage for each runner?

SELECT
    runner_id,
    ROUND((SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) / COUNT(order_id) * 100), 2) AS successful_delivery_percentage
FROM runner_orders_updated
GROUP BY runner_id;

-- C. Ingredient Optimisation
-- C.1. What are the standard ingredients for each pizza?
-- Method 1

SELECT
    pn.pizza_name,
    GROUP_CONCAT(pt.topping_name) AS standard_ingredients
FROM
    pizza_recipes_updated_optional pr
        JOIN
    pizza_names pn ON pr.pizza_id = pn.pizza_id
        JOIN
    pizza_toppings pt ON pt.topping_id = pr.toppings
GROUP BY pn.pizza_name;

-- Method 2

SELECT
    pn.pizza_name,
    GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS standard_ingredients
FROM
    pizza_recipes pr
        LEFT JOIN
    pizza_toppings pt ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', '')) > 0
        JOIN
    pizza_names pn ON pr.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name;

-- C.2. What was the most commonly added extra?
-- Method 1

SELECT
    co.extras,
    pt.topping_name,
    COUNT(co.extras) AS extras_count
FROM 
    customer_orders_updated_optional co
        JOIN
    pizza_toppings pt ON pt.topping_id = co.extras
WHERE extras IS NOT NULL
GROUP BY co.extras, pt.topping_name
ORDER BY extras_count DESC
LIMIT 1;

-- Method 2

SELECT 
    pt_extras.topping_name,
    COUNT(pt_extras.topping_name) AS extras_count
FROM 
    customer_orders_updated co
        LEFT JOIN 
    pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, REPLACE(co.extras, ' ', '')) > 0
WHERE co.extras != ''
GROUP BY pt_extras.topping_name
ORDER BY extras_count DESC
LIMIT 1;

-- C.3. What was the most common exclusion?
-- Method 1

SELECT
    co.exclusions,
    pt.topping_name,
    COUNT(co.exclusions) AS exclusion_count
FROM 
    customer_orders_updated_optional co
        JOIN
    pizza_toppings pt ON pt.topping_id = co.exclusions
WHERE co.exclusions != ''
GROUP BY co.exclusions, pt.topping_name
ORDER BY exclusion_count DESC
LIMIT 1;

-- Method 2

SELECT 
    pt_exclude.topping_name,
    COUNT(pt_exclude.topping_name) AS exclusion_count
FROM 
    customer_orders_updated co
        LEFT JOIN 
    pizza_toppings pt_exclude ON FIND_IN_SET(pt_exclude.topping_id, REPLACE(co.exclusions, ' ', '')) > 0
WHERE co.exclusions != ''
GROUP BY pt_exclude.topping_name
ORDER BY exclusion_count DESC
LIMIT 1;

-- C.4. Generate an order item for each record in the customers_orders table in the format of one of the following:
      -- Meat Lovers
      -- Meat Lovers - Exclude Beef
      -- Meat Lovers - Extra Bacon
      -- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH cte_split AS (
    SELECT 
        co.order_id,
        pn.pizza_name,
        CONCAT('Exclude ', GROUP_CONCAT(DISTINCT pt_exclude.topping_name ORDER BY pt_exclude.topping_id SEPARATOR ', ')) AS exclusions,
        CONCAT('Extra ', GROUP_CONCAT(DISTINCT pt_extras.topping_name ORDER BY pt_extras.topping_id SEPARATOR ', ')) AS extras
    FROM 
        customer_orders_updated co
            LEFT JOIN 
        pizza_names pn ON co.pizza_id = pn.pizza_id
            LEFT JOIN 
        pizza_toppings pt_exclude ON FIND_IN_SET(pt_exclude.topping_id, REPLACE(co.exclusions, ' ', '')) > 0
            LEFT JOIN 
        pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, REPLACE(co.extras, ' ', '')) > 0
    GROUP BY co.order_id, pn.pizza_name)
SELECT 
    order_id, 
    CONCAT_WS(' - ', pizza_name, exclusions, extras) AS order_details
FROM cte_split;
	
-- C.5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
      -- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH cte_customer_orders AS (
    SELECT 
        *,
        ROW_NUMBER() OVER () AS row_sequence
    FROM customer_orders_updated),
cte_topping AS (
    SELECT 
        co.order_id,
        pn.pizza_name,
        pt.topping_id,
        pt.topping_name AS topping,
        co.row_sequence
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            JOIN 
        pizza_names pn ON co.pizza_id = pn.pizza_id
            LEFT JOIN
        pizza_toppings pt ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', '')) > 0),
cte_extras AS (
    SELECT 
        co.order_id,
        pn.pizza_name,
        pt_extras.topping_id,
        pt_extras.topping_name AS topping,
        co.row_sequence
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            JOIN 
        pizza_names pn ON co.pizza_id = pn.pizza_id
            LEFT JOIN
        pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, REPLACE(co.extras, ' ', '')) > 0),
cte_union AS (
    SELECT 
        co.order_id,
        pn.pizza_name,
        pt.topping_id,
        CASE
            WHEN pt.topping_name = pt_extras.topping_name THEN CONCAT('2x', pt.topping_name) 
            ELSE pt.topping_name END AS topping,
        co.row_sequence
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            JOIN 
        pizza_names pn ON co.pizza_id = pn.pizza_id
            LEFT JOIN
        pizza_toppings pt ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', '')) > 0
            LEFT JOIN
        pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, REPLACE(co.extras, ' ', '')) > 0
    UNION
    SELECT 
        co.order_id,
        pn.pizza_name,
        pt_extras.topping_id,
        pt_extras.topping_name AS topping,
        co.row_sequence
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            JOIN 
        pizza_names pn ON co.pizza_id = pn.pizza_id
            LEFT JOIN
        pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, REPLACE(co.extras, ' ', '')) > 0),
cte_update_extras AS (
    SELECT
        a.order_id,
        a.pizza_name,
        a.topping_id,
        a.topping,
        a.row_sequence
    FROM
        cte_union a
            LEFT JOIN 
        cte_extras b ON a.order_id = b.order_id AND a.pizza_name = b.pizza_name AND a.topping = b.topping AND a.row_sequence = b.row_sequence
            LEFT JOIN
        cte_topping c ON a.order_id = c.order_id AND a.pizza_name = c.pizza_name AND a.topping = c.topping AND a.row_sequence = c.row_sequence
    WHERE b.topping IS NULL OR (b.topping IS NOT NULL AND c.topping IS NULL)),
cte_exclude AS (
    SELECT 
        co.order_id,
        pn.pizza_name,
        pt_exclude.topping_id,
        pt_exclude.topping_name AS topping,
        co.row_sequence
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            JOIN 
        pizza_names pn ON co.pizza_id = pn.pizza_id
            LEFT JOIN
        pizza_toppings pt_exclude ON FIND_IN_SET(pt_exclude.topping_id, REPLACE(co.exclusions, ' ', '')) > 0),
cte_combined AS (
    SELECT
        a.order_id,
        a.pizza_name,
        a.topping_id,
        a.topping,
        a.row_sequence
    FROM
        cte_update_extras a
            LEFT JOIN 
        cte_exclude b ON a.order_id = b.order_id AND a.pizza_name = b.pizza_name AND a.topping = b.topping AND a.row_sequence = b.row_sequence
    WHERE b.topping IS NULL)
SELECT 
    c.order_id,
    CONCAT(c.pizza_name, ': ', GROUP_CONCAT(DISTINCT c.topping ORDER BY c.topping_id SEPARATOR ', ')) AS ingredients
FROM 
    cte_combined c
        LEFT JOIN
    pizza_toppings t ON c.topping = t.topping_name
GROUP BY c.row_sequence, c.order_id, c.pizza_name;
      
-- C.6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH cte_customer_orders AS (
    SELECT 
        *,
        ROW_NUMBER() OVER () AS row_sequence
    FROM customer_orders_updated),
cte_union AS (
    SELECT 
        co.row_sequence,
        co.order_id,
        pt.topping_name AS topping
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            LEFT JOIN
        pizza_toppings pt ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', '')) > 0
    UNION ALL
    SELECT 
        co.row_sequence,
        co.order_id,
        pt_extras.topping_name AS topping
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            LEFT JOIN
        pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, REPLACE(co.extras, ' ', '')) > 0),
cte_exclude AS (
    SELECT 
        co.row_sequence,
        co.order_id,
        pt_exclude.topping_name AS topping
    FROM 
        cte_customer_orders co
            JOIN
        pizza_recipes pr ON co.pizza_id = pr.pizza_id
            LEFT JOIN
        pizza_toppings pt_exclude ON FIND_IN_SET(pt_exclude.topping_id, REPLACE(co.exclusions, ' ', '')) > 0),
cte_combined AS (
    SELECT
        a.row_sequence,
        a.order_id,
        a.topping
    FROM
        cte_union a
            LEFT JOIN 
        cte_exclude b ON a.order_id = b.order_id AND a.topping = b.topping AND a.row_sequence = b.row_sequence
            JOIN
        runner_orders_updated c ON a.order_id = c.order_id
    WHERE b.topping IS NULL AND c.cancellation IS NULL)
SELECT
    topping AS ingredient,
    COUNT(topping) AS quantity
FROM cte_combined
WHERE topping IS NOT NULL
GROUP BY ingredient
ORDER BY quantity DESC;
	
-- D. Pricing and Ratings
-- D.1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT
    SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12 ELSE 10 END) AS total_money_made
FROM
    runner_orders_updated r
        JOIN
    customer_orders_updated c USING (order_id)
        JOIN
    pizza_names p USING (pizza_id)
WHERE cancellation IS NULL;

-- D.2. What if there was an additional $1 charge for any pizza extras?
      -- Add cheese is $1 extra

WITH cte_pizza_price AS (
    SELECT
        SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12 ELSE 10 END) AS total_pizza_price
    FROM
        runner_orders_updated r
            JOIN
        customer_orders_updated c USING (order_id)
            JOIN
        pizza_names p USING (pizza_id)
    WHERE cancellation IS NULL),
cte_extras AS (
    SELECT 
        SUM(CASE WHEN pt_extras.topping_name = 'Cheese' THEN 2 ELSE 1 END) AS extra_charge
    FROM 
        customer_orders_updated c
            LEFT JOIN
        pizza_toppings pt_extras ON FIND_IN_SET(pt_extras.topping_id, REPLACE(c.extras, ' ', '')) > 0
    WHERE pt_extras.topping_id IS NOT NULL)
SELECT
    total_pizza_price + extra_charge AS total_charge
FROM
    cte_pizza_price 
        JOIN
    cte_extras;

-- D.3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (order_id INT, rating INT);
INSERT INTO ratings (order_id, rating)
VALUES  (1,5), (2,4), (3,3), (4,1), (5,2), (7,3), (8,5), (10,4);

SELECT * FROM ratings;

-- D.4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
      -- customer_id
      -- order_id
      -- runner_id
      -- rating
      -- order_time
      -- pickup_time
      -- Time between order and pickup
      -- Delivery duration
      -- Average speed
      -- Total number of pizzas

SELECT	
    customer_id,
    order_id,
    runner_id,
    rating,
    order_time,
    pickup_time,
    MINUTE(TIMEDIFF(pickup_time, order_time)) AS time_diff_in_minute_between_order_and_pickup,
    duration AS delivery_duration,
    ROUND(AVG(distance / (duration / 60)), 2) AS average_speed_kph,
    COUNT(pizza_id) AS total_number_of_pizzas
FROM
    customer_orders_updated
        JOIN
    runner_orders_updated USING (order_id)
        JOIN
    ratings USING (order_id)
WHERE cancellation IS NULL
GROUP BY 
    customer_id, 
    order_id, 
    runner_id, 
    rating, 
    order_time, 
    pickup_time, 
    time_diff_in_minute_between_order_and_pickup, 
    delivery_duration
ORDER BY customer_id;

-- D.5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH cte_pizza_price AS (
    SELECT
        SUM(CASE WHEN pizza_name = 'MeatLovers' THEN 12 ELSE 10 END) AS pizza_revenue
    FROM
        customer_orders_updated 
            JOIN
        runner_orders_updated USING (order_id)
            JOIN
        pizza_names USING (pizza_id)
    WHERE cancellation IS NULL),
cte_delivery_cost AS (
    SELECT
        ROUND(SUM(distance) * 0.3, 2) AS delivery_cost
    FROM runner_orders_updated 
    WHERE cancellation IS NULL)
SELECT
    pizza_revenue,
    delivery_cost,
    (pizza_revenue - delivery_cost) AS total_left_over
FROM 
    cte_pizza_price
        JOIN
    cte_delivery_cost;

-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
