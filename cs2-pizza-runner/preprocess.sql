USE pizza_runner;

DESCRIBE customer_orders;

SELECT * FROM customer_orders;

DESCRIBE runner_orders;

SELECT * FROM runner_orders;

DESCRIBE pizza_names;

SELECT * FROM pizza_names;

DESCRIBE pizza_recipes;

SELECT * FROM pizza_recipes;

DESCRIBE pizza_toppings;

SELECT * FROM pizza_toppings;

DESCRIBE runners;

SELECT * FROM runner;

-- Data cleaning and type correction

-- 1. Clean up `null` values, and correct the variable types in customer_orders table.

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

-- 2. Clean up 'null' values, and correct the variable types in runner_orders table.

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

-- 3. Separate each topping in pizza_recipes to separate rows (optional)
-- Reference: https://www.machinelearningplus.com/sql/how-to-split-values-to-multiple-rows-in-sql/

DESCRIBE pizza_recipes;

DROP TABLE IF EXISTS pizza_recipes_updated_optional;
CREATE TABLE pizza_recipes_updated_optional (pizza_id INT, toppings INT);

INSERT INTO pizza_recipes_updated_optional
WITH RECURSIVE pizza_recipes_updated_optional AS (
	SELECT
		pizza_id,
		SUBSTRING_INDEX(toppings, ',', 1) AS split_value,
		IF(LOCATE(',', toppings) > 0, SUBSTRING(toppings, LOCATE(',', toppings) + 1), NULL) AS remaining_values
	FROM
		pizza_recipes
	UNION ALL
	SELECT
		pizza_id,
		SUBSTRING_INDEX(remaining_values, ',', 1) AS split_value,
		IF(LOCATE(',', remaining_values) > 0, SUBSTRING(remaining_values, LOCATE(',', remaining_values) + 1), NULL)
	FROM
		pizza_recipes_updated_optional
	WHERE
		remaining_values IS NOT NULL
)
SELECT
	pizza_id,
	split_value
FROM
	pizza_recipes_updated_optional
ORDER BY pizza_id;

SELECT * FROM pizza_recipes_updated_optional;

-- 4. Separate each item in extras and exclusions column in in customer_orders_updated to separate rows (optional)
-- Reference: https://www.machinelearningplus.com/sql/how-to-split-values-to-multiple-rows-in-sql/

DESCRIBE customer_orders_updated;

DROP TABLE IF EXISTS customer_orders_updated_optional;
CREATE TABLE customer_orders_updated_optional (order_id INT, customer_id INT, pizza_id INT, exclusions VARCHAR(4), extras VARCHAR(4), order_time DATETIME);

INSERT INTO customer_orders_updated_optional
WITH RECURSIVE customer_orders_updated_optional AS (
	SELECT
		order_id,
        customer_id,
        pizza_id,
		SUBSTRING_INDEX(exclusions, ',', 1) AS exclusions_split_value,
		IF(LOCATE(',', exclusions) > 0, SUBSTRING(exclusions, LOCATE(',', exclusions) + 1), '') AS exclusions_remaining_values,
        SUBSTRING_INDEX(extras, ',', 1) AS extras_split_value,
		IF(LOCATE(',', extras) > 0, SUBSTRING(extras, LOCATE(',', extras) + 1), '') AS extras_remaining_values,
        order_time
	FROM
		customer_orders_updated
	UNION ALL
	SELECT
		order_id,
        customer_id,
        pizza_id,
		SUBSTRING_INDEX(exclusions_remaining_values, ',', 1) AS exclusions_split_value,
		IF(LOCATE(',', exclusions_remaining_values) > 0, SUBSTRING(exclusions_remaining_values, LOCATE(', ', exclusions_remaining_values) + 1), ''),
        SUBSTRING_INDEX(extras_remaining_values, ',', 1) AS extras_split_value,
		IF(LOCATE(',', extras_remaining_values) > 0, SUBSTRING(extras_remaining_values, LOCATE(',', extras_remaining_values) + 1), ''),
        order_time
	FROM
		customer_orders_updated_optional
	WHERE
		exclusions_remaining_values != '' OR extras_remaining_values != ''
)
SELECT
	order_id,
	customer_id,
	pizza_id,
    exclusions_split_value,
    extras_split_value,
    order_time
FROM
	customer_orders_updated_optional
ORDER BY order_id;

SELECT * FROM customer_orders_updated_optional;
