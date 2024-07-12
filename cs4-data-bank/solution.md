# Case Study #4 Data Bank

## A. Customer Nodes Exploration

### 1. How many unique nodes are there on the Data Bank system?
```sql
SELECT
    COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;
```

<img width="119" alt="image" src="https://github.com/user-attachments/assets/46f97079-39f5-4811-bc3b-eb2ea55017ba">

### 2. What is the number of nodes per region?
```sql
SELECT
    r.region_name,
    COUNT(n.node_id) AS node_count
FROM 
    customer_nodes n
        JOIN
    regions r ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY node_count DESC;
```

<img width="210" alt="image" src="https://github.com/user-attachments/assets/7715953d-8e23-4c38-b056-1bf61f732cd6">

### 3. How many customers are allocated to each region?
```sql
SELECT
    r.region_name,
    COUNT(DISTINCT n.customer_id) AS customer_count
FROM
    customer_nodes n
        JOIN
    regions r ON n.region_id = r.region_id
GROUP BY r.region_name
ORDER BY customer_count DESC;
```

<img width="243" alt="image" src="https://github.com/user-attachments/assets/29885783-8ac5-47d7-9810-44926b4c6087">

### 4. How many days on average are customers reallocated to a different node?
```sql
SELECT end_date
FROM customer_nodes
WHERE YEAR(end_date) != '2020';

SELECT
    ROUND(AVG(DATEDIFF(end_date, start_date))) AS average_days
FROM customer_nodes
WHERE end_date != '9999-12-31';
```

<img width="117" alt="image" src="https://github.com/user-attachments/assets/cd11fd20-f6c8-4fec-b939-3af9bd814c95">

### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
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
```

<img width="395" alt="image" src="https://github.com/user-attachments/assets/ed4f14a6-f1c5-486a-b0f2-b929bb4f1931">

## B. Customer Transactions

### 1. What is the unique count and total amount for each transaction type?
```sql
SELECT
    txn_type,
    COUNT(txn_type) AS unique_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;
```

<img width="315" alt="image" src="https://github.com/user-attachments/assets/4bec3fe5-635c-4158-b760-78ebf98d846d">

### 2. What is the average total historical deposit counts and amounts for all customers?
```sql
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
```

<img width="371" alt="image" src="https://github.com/user-attachments/assets/3e9470c2-941e-4de1-b436-7e08ae7ca037">

### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
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
```

<img width="197" alt="image" src="https://github.com/user-attachments/assets/1a71fb79-df05-4de0-927b-aed89da2eae1">

### 4. What is the closing balance for each customer at the end of the month?
```sql
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
```

<img width="333" alt="image" src="https://github.com/user-attachments/assets/9c67338c-2075-4384-9348-19930e789fe1">

The is just a part of the table. There is a total of 1720 rows in the table.

### 5. What is the percentage of customers who increase their closing balance by more than 5%?
```sql
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
```

<img width="176" alt="image" src="https://github.com/user-attachments/assets/50182d9b-bb56-4e20-a6c7-f858a0c0c008">
