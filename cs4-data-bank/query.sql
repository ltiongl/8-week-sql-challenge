-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #4 - Data Bank

USE data_bank;

-- A. Customer Nodes Exploration
-- A.1. How many unique nodes are there on the Data Bank system?

SELECT
	COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

-- A.2. What is the number of nodes per region?

SELECT
	r.region_name,
	COUNT(n.node_id) AS node_count
FROM 
	customer_nodes n
		JOIN
	regions r ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY node_count DESC;

-- A.3. How many customers are allocated to each region?

SELECT
	r.region_name,
	COUNT(DISTINCT n.customer_id) AS customer_count
FROM
	customer_nodes n
		JOIN
	regions r ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY customer_count DESC;

-- A.4. How many days on average are customers reallocated to a different node?

SELECT end_date
FROM customer_nodes
WHERE YEAR(end_date) != '2020';

SELECT
	ROUND(AVG(DATEDIFF(end_date, start_date))) AS average_days
FROM customer_nodes
WHERE end_date != '9999-12-31';

-- A.5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH cte_days AS (
	SELECT
		*,
		DATEDIFF(end_date, start_date) AS reallocation_days
	FROM 
		customer_nodes 
			JOIN
		regions USING(region_id)
	WHERE end_date != '9999-12-31'),
cte_percentile AS (
	SELECT
		*,
        PERCENT_RANK() OVER (PARTITION BY region_id ORDER BY reallocation_days) AS percentile
	FROM cte_days)
SELECT 
	DISTINCT region_name,
    FIRST_VALUE (reallocation_days) OVER (ORDER BY CASE WHEN percentile <= 0.5 THEN percentile END) AS median,
    FIRST_VALUE (reallocation_days) OVER (ORDER BY CASE WHEN percentile <= 0.8 THEN percentile END) AS percentile_80,
    FIRST_VALUE (reallocation_days) OVER (ORDER BY CASE WHEN percentile <= 0.95 THEN percentile END) AS percentile_95
FROM cte_percentile;
	
-- B. Customer Transactions
-- B.1. What is the unique count and total amount for each transaction type?

SELECT
	txn_type,
	COUNT(txn_type) AS unique_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

-- B.2. What is the average total historical deposit counts and amounts for all customers?

WITH cte_customer_categorised AS (
	SELECT
		customer_id,
		COUNT(txn_amount) total_deposit,
		SUM(txn_amount) average_amount
	FROM customer_transactions
	WHERE txn_type = 'deposit'
	GROUP BY customer_id)
SELECT
	ROUND(AVG(total_deposit)) AS average_total_deposit,
    ROUND(AVG(average_amount)) AS average_deposit_amount
FROM cte_customer_categorised;

-- B.3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH cte_transaction AS (
	SELECT
		MONTH(txn_date) AS month,
		customer_id,
		SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit,
		SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase,
		SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal
	FROM customer_transactions
	GROUP BY customer_id, month)
SELECT
	month,
    COUNT(customer_id) AS customer_count
FROM cte_transaction
WHERE deposit > 1 AND (purchase = 1 OR withdrawal = 1)
GROUP BY month
ORDER BY month;

-- B.4. What is the closing balance for each customer at the end of the month?

WITH cte_transaction_amount AS (
	SELECT
		customer_id,
		MONTH(txn_date) AS txn_month,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE - txn_amount END) AS amount
	FROM customer_transactions
	GROUP BY txn_month, customer_id
    ORDER BY txn_month, customer_id)
SELECT 
	*, 
	SUM(amount) OVER (PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) balance
FROM cte_transaction_amount
GROUP BY customer_id, txn_month, amount;

-- B.5. What is the percentage of customers who increase their closing balance by more than 5%?

WITH cte_transaction_amount AS (
	SELECT
		customer_id,
		MONTH(txn_date) AS txn_month,
		SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE - txn_amount END) AS amount
	FROM customer_transactions
	GROUP BY txn_month, customer_id),
cte_closing_balance AS (
	SELECT 
		customer_id, 
        txn_month,
		SUM(amount) OVER(PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS balance
	FROM cte_transaction_amount
	GROUP BY customer_id, txn_month, amount),
cte_filter_balance AS (
	SELECT
		DISTINCT customer_id,
        FIRST_VALUE(balance) OVER (PARTITION BY customer_id ORDER BY customer_id) AS first_balance,
		LAST_VALUE(balance) OVER (PARTITION BY customer_id ORDER BY customer_id) AS last_balance
	FROM cte_closing_balance),
cte_balance_percentage AS (
	SELECT
		customer_id,
        ROUND((last_balance - first_balance) / first_balance * 100, 2) AS growing_balance_percentage
	FROM cte_filter_balance
    WHERE ROUND((last_balance - first_balance) / first_balance * 100, 2) > 5)
SELECT
	ROUND(COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) * 100, 2) AS customer_percentage
FROM cte_balance_percentage;
