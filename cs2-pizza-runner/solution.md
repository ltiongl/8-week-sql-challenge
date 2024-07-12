# [Case Study #2 - Pizza Runner](https://8weeksqlchallenge.com/case-study-2/)

## Data Cleaning
### 1. Clean up `null` values, and correct the variable types in `customer_orders` table.
```sql
DROP TABLE IF EXISTS customer_orders_updated;
CREATE TABLE customer_orders_updated (order_id INT, customer_id INT, pizza_id INT, exclusions VARCHAR(4), extras VARCHAR(4), order_time TIMESTAMP);

INSERT INTO customer_orders_updated
SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE
        WHEN exclusions IS NULL OR exclusions like 'null' THEN ''
        ELSE exclusions
    END AS exclusions,
    CASE
        WHEN extras IS NULL OR extras like 'null' THEN ''
        ELSE extras
    END AS extras,
    order_time
FROM customer_orders;

DESCRIBE customer_orders_updated;
SELECT * FROM customer_orders_updated;

ALTER TABLE customer_orders_updated
MODIFY COLUMN order_time DATETIME;
```

<img width="552" alt="image" src="https://github.com/user-attachments/assets/c147bd20-dba0-424d-a948-0f886297a848">

### 2. Clean up `null` values, and correct the variable types in `runner_orders` table.
```sql
DROP TABLE IF EXISTS runner_orders_updated;
CREATE TABLE runner_orders_updated (order_id INT, runner_id INT, pickup_time VARCHAR(19), distance VARCHAR(7), duration VARCHAR(10), cancellation VARCHAR(23));

INSERT INTO runner_orders_updated
SELECT 
    order_id,
    runner_id,
    CASE
        WHEN pickup_time LIKE "null" THEN NULL
        ELSE pickup_time
    END AS pickup_time,
    CASE
        WHEN distance LIKE "null" THEN NULL
        WHEN distance LIKE "%km" THEN TRIM(TRAILING 'km' FROM distance)
        ELSE distance
    END AS distance,
    CASE
        WHEN duration LIKE "null" THEN NULL
        WHEN duration LIKE "%mins" THEN TRIM(TRAILING 'mins' FROM duration)
        WHEN duration LIKE "%minutes" THEN TRIM(TRAILING 'minutes' FROM duration)
        WHEN duration LIKE "%minute" THEN TRIM(TRAILING 'minute' FROM duration)
        ELSE duration
    END AS duration,
    CASE
        WHEN cancellation = '' OR cancellation LIKE "null" THEN NULL
        ELSE cancellation
    END AS cancellation
FROM runner_orders;

DESCRIBE runner_orders_updated;

SELECT * FROM runner_orders_updated;

ALTER TABLE runner_orders_updated
MODIFY COLUMN pickup_time DATETIME,
MODIFY COLUMN distance FLOAT, 
MODIFY COLUMN duration INT;
```

<img width="636" alt="image" src="https://github.com/user-attachments/assets/fa2807ed-7d7e-4550-82c0-9bd4c98c371d">

Please refer to [preprocess.sql](https://github.com/ltiongl/8-week-sql-challenge/blob/main/cs2-pizza-runner/preprocess.sql) for data cleaning queries.

## A. Pizza Metrics

### 1. How many pizzas were ordered?
```sql
SELECT 
    COUNT(order_id) AS pizza_order_count
FROM customer_orders_updated;
```

<img width="150" alt="image" src="https://github.com/user-attachments/assets/8fd811ef-135f-421a-a059-eb907bdb456b">

### 2. How many unique customer orders were made?
```sql
SELECT 
    COUNT(DISTINCT order_id) AS unique_customer_order_count
FROM
    customer_orders_updated;
```

<img width="237" alt="image" src="https://github.com/user-attachments/assets/84a71ab5-d16c-4cd7-be98-a7386839236f">

### 3. How many successful orders were delivered by each runner?
```sql
SELECT 
    runner_id,
    COUNT(order_id) AS successful_delivery
FROM runner_orders_updated
WHERE distance IS NOT NULL
GROUP BY runner_id;
```

<img width="240" alt="image" src="https://github.com/user-attachments/assets/65508996-a1ac-4ccb-b58b-570017ac584d">

### 4. How many of each type of pizza was delivered?
```sql
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
```

<img width="227" alt="image" src="https://github.com/user-attachments/assets/5658881a-a390-47fb-b778-f105f9bb0ff1">

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
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
```

<img width="291" alt="image" src="https://github.com/user-attachments/assets/59bbbef4-1fcf-4348-99b0-cee6fceadcff">

### 6. What was the maximum number of pizzas delivered in a single order?
```sql
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
```

<img width="177" alt="image" src="https://github.com/user-attachments/assets/169e999b-766a-47a0-a53b-88f45acdcc6b">

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
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
```

<img width="498" alt="image" src="https://github.com/user-attachments/assets/ae4a4cc6-97a1-4dca-94b6-7b2196ea7c91">

### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT
    COUNT(pizza_id) AS pizza_count
FROM
    customer_orders_updated
        JOIN
    runner_orders_updated USING (order_id)
WHERE distance IS NOT NULL AND (exclusions != '' AND extras != '')
GROUP BY customer_id
ORDER BY customer_id;
```

<img width="105" alt="image" src="https://github.com/user-attachments/assets/1c34ae0d-c8b5-4bbf-8428-c31dd1a4c56a">

### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT
    HOUR(order_time) AS hour,
    COUNT(order_id) AS pizza_count
FROM customer_orders_updated
GROUP BY hour
ORDER BY hour;
```
<img width="152" alt="image" src="https://github.com/user-attachments/assets/6adebcaa-2f12-4975-89dc-37e952071d07">

### 10. What was the volume of orders for each day of the week?
```sql
SELECT
    DAYNAME(order_time) AS day,
    COUNT(order_id) AS order_count
FROM customer_orders_updated
GROUP BY day;
```

<img width="203" alt="image" src="https://github.com/user-attachments/assets/29e0af11-7925-43cf-8db5-fff4b751e7d5">

## B. Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT
    WEEK(registration_date) AS week,
    COUNT(runner_id) AS runner_count
FROM runners
GROUP BY week;
```

<img width="167" alt="image" src="https://github.com/user-attachments/assets/65e3d4af-d134-43c5-978d-62172d4de832">

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT
    runner_id,
    ROUND(AVG(MINUTE(TIMEDIFF(pickup_time, order_time))), 2) AS average_time_in_min
FROM
    runner_orders_updated
        JOIN
    customer_orders_updated USING (order_id)
GROUP BY runner_id;
```

<img width="251" alt="image" src="https://github.com/user-attachments/assets/12ad4569-5380-4846-a7d8-5808f46bad34">

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
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
```

<img width="332" alt="image" src="https://github.com/user-attachments/assets/0e6de549-1dac-4a64-b52d-78efbe3721ce">

### 4. What was the average distance travelled for each customer?
```sql
SELECT
    customer_id,
    ROUND(AVG(distance), 2) AS average_distance
FROM
    customer_orders_updated 
        JOIN
    runner_orders_updated USING (order_id)
GROUP BY customer_id
ORDER BY customer_id;
```
customer_id	average_distance

<img width="248" alt="image" src="https://github.com/user-attachments/assets/aee1d394-6eda-4292-a3a1-a983b948c582">

### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT
    (MAX(duration) - MIN(duration)) AS diff_delivery_time
FROM runner_orders_updated;
```

<img width="144" alt="image" src="https://github.com/user-attachments/assets/9b206c86-3288-4ef7-b368-d63d2cd0f281">

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT
    runner_id,
    order_id,
    ROUND(AVG(distance / (duration / 60)), 2) AS average_speed
FROM runner_orders_updated
WHERE distance IS NOT NULL
GROUP BY runner_id, order_id
ORDER BY runner_id;
```

<img width="281" alt="image" src="https://github.com/user-attachments/assets/5a78754a-0fcb-4a31-b429-de4fd8752e65">

### 7. What is the successful delivery percentage for each runner?
```sql
SELECT
    runner_id,
    ROUND((SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) / COUNT(order_id) * 100), 2) AS successful_delivery_percentage
FROM runner_orders_updated
GROUP BY runner_id;
```

<img width="329" alt="image" src="https://github.com/user-attachments/assets/7e7dc76b-a39e-4399-96a9-d94f9a7b28ef">

## C. Ingredient Optimisation

### 1. What are the standard ingredients for each pizza?
```sql
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
```

<img width="926" alt="image" src="https://github.com/user-attachments/assets/33ff4003-0d6a-469b-b11b-e58a209d6fef">

### 2. What was the most commonly added extra?
```sql
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
```

<img width="287" alt="image" src="https://github.com/user-attachments/assets/cfed0c2f-5638-454a-a1de-71d740c428c9">

### 3. What was the most common exclusion?
```sql
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
```

<img width="252" alt="image" src="https://github.com/user-attachments/assets/75888599-db63-4c6c-9c40-9788b28c85de">

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
* `Meat Lovers`
* `Meat Lovers - Exclude Beef`
* `Meat Lovers - Extra Bacon`
* `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`
```sql
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
```

<img width="560" alt="image" src="https://github.com/user-attachments/assets/55804256-0187-4f7f-9599-1230dc7bb983">

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
* For example: `Meat Lovers: 2xBacon, Beef, ... , Salami`
```sql
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
```

<img width="701" alt="image" src="https://github.com/user-attachments/assets/c111c393-6ae6-4410-8f51-83fe1745a990">

### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
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
```

<img width="194" alt="image" src="https://github.com/user-attachments/assets/5b2b4a08-962a-4c21-8687-7254f8f31973">

## D. Pricing and Ratings

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```sql
SELECT
    SUM(CASE WHEN pizza_name = 'Meatlovers' THEN 12 ELSE 10 END) AS total_money_made
FROM
    runner_orders_updated r
        JOIN
    customer_orders_updated c USING (order_id)
        JOIN
    pizza_names p USING (pizza_id)
WHERE cancellation IS NULL;
```

<img width="155" alt="image" src="https://github.com/user-attachments/assets/1e0ba68b-0449-45c6-b8c9-fcf8dec5c701">

### 2. What if there was an additional $1 charge for any pizza extras?
* Add cheese is $1 extra
```sql
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
```

<img width="108" alt="image" src="https://github.com/user-attachments/assets/f6c4b5c4-bee5-4831-864b-58650b3f69c7">

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```sql
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (order_id INT, rating INT);
INSERT INTO ratings (order_id, rating)
VALUES  (1,5), (2,4), (3,3), (4,1), (5,2), (7,3), (8,5), (10,4);

SELECT * FROM ratings;
```

<img width="124" alt="image" src="https://github.com/user-attachments/assets/907fca71-1c35-4aea-9c5c-4ee383cb1bf2">

### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
* `customer_id`
* `order_id`
* `runner_id`
* `rating`
* `order_time`
* `pickup_time`
* Time between order and pickup
* Delivery duration
* Average speed
* Total number of pizzas
```sql
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
```

<img width="1458" alt="image" src="https://github.com/user-attachments/assets/50d20bbb-5847-4e3c-b7ce-8241b6e152f2">

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```sql
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
```

<img width="344" alt="image" src="https://github.com/user-attachments/assets/2e65ff52-d0bf-4b56-a658-2c2ac7355ea9">

## E. Bonus Questions

If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
```sql
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
```

<img width="176" alt="image" src="https://github.com/user-attachments/assets/64d60fa6-b455-4a89-ba15-fc43009fd349">
<img width="309" alt="image" src="https://github.com/user-attachments/assets/98330942-f9a1-47cd-80ac-7a84f0f0a745">
