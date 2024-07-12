### Case Study #3 - Foodie-Fi

## A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

```sql
SELECT
    customer_id,
    plan_name,
    start_date,
    price
FROM
    plans 
        JOIN
    subscriptions USING (plan_id);
```

<img width="365" alt="image" src="https://github.com/user-attachments/assets/7ab1110c-5eda-4505-89db-f36b4c79fe0b">

The is just a part of the table. There is a total of 2650 rows in the table.

## B. Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
```sql
SELECT
    COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions;
```

<img width="135" alt="image" src="https://github.com/user-attachments/assets/107e6eb8-5c33-4484-8412-6a58e1650d83">

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
SELECT
    MONTHNAME(start_date) AS month,
    COUNT(plan_id) AS trial_distributions
FROM
    plans 
        JOIN
    subscriptions USING (plan_id)
WHERE plan_id = 0
GROUP BY month
ORDER BY trial_distributions DESC;
```
<img width="236" alt="image" src="https://github.com/user-attachments/assets/295c9ae0-02b5-4b0d-843f-30e992d6b056">

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
SELECT
    plan_id,
    plan_name,
    COUNT(plan_id) AS count_of_events
FROM
    plans 
        JOIN
    subscriptions USING (plan_id)
WHERE YEAR(start_date) > 2020
GROUP BY plan_id, plan_name
ORDER BY plan_id;
```

<img width="308" alt="image" src="https://github.com/user-attachments/assets/2e0fb949-d1e9-45b0-ae2f-3695221b1196">

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT
    SUM(CASE WHEN plan_name = 'churn' THEN 1 END) AS customer_count,
    ROUND(SUM(CASE WHEN plan_name = 'churn' THEN 1 END) / COUNT(DISTINCT customer_id) * 100, 1) AS churn_percentage
FROM 
    subscriptions 
        JOIN
    plans USING (plan_id);
```

<img width="275" alt="image" src="https://github.com/user-attachments/assets/b9e21fe5-e010-4c3c-9ae9-e25d9d239be4">


### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
WITH cte_rank AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_rank
    FROM subscriptions)
SELECT
    SUM(CASE WHEN plan_name = 'churn' AND plan_rank = 2 THEN 1 END) AS churned_customers_after_trial,
    ROUND(SUM(CASE WHEN plan_name = 'churn' AND plan_rank = 2 THEN 1 END) / COUNT(DISTINCT customer_id) * 100, 0) AS churn_percentage
FROM
    cte_rank 
        JOIN
    plans USING (plan_id);
```

<img width="383" alt="image" src="https://github.com/user-attachments/assets/8b1295f4-1d9d-4a29-a28e-301e7f1b3362">

### 6. What is the number and percentage of customer plans after their initial free trial?
```sql
WITH cte_rank AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_rank
    FROM subscriptions)
SELECT
    plan_id,
    plan_name,
    COUNT(plan_id) AS conversions,
    ROUND(COUNT(plan_id) / (SELECT COUNT(plan_id) FROM cte_rank WHERE plan_rank = 2) * 100, 1) AS conversion_percentage
FROM 
    cte_rank 
        JOIN
    plans USING (plan_id)
WHERE plan_rank = 2
GROUP BY plan_id, plan_name
ORDER BY plan_id;
```

<img width="459" alt="image" src="https://github.com/user-attachments/assets/f706527d-aa2c-4dc4-a112-532113c78dec">

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
WITH cte_rank AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS plan_rank
    FROM subscriptions
    WHERE start_date <= '2020-12-31')
SELECT
    plan_name,
    COUNT(plan_id) AS customer_count,
    ROUND(COUNT(plan_id) / (SELECT COUNT(customer_id) FROM cte_rank WHERE plan_rank = 1) * 100, 1) AS percentage
FROM 
    cte_rank 
        JOIN
    plans USING (plan_id)
WHERE plan_rank = 1
GROUP BY plan_name
ORDER BY customer_count DESC;
```

<img width="345" alt="image" src="https://github.com/user-attachments/assets/58626e4b-2927-4d59-be0a-6aec5436c9ce">

### 8. How many customers have upgraded to an annual plan in 2020?
```sql
SELECT
    COUNT(customer_id) AS customer_count
FROM 
    subscriptions 
        JOIN
    plans USING (plan_id)
WHERE YEAR(start_date) = 2020 AND plan_name = 'pro annual';
```

<img width="135" alt="image" src="https://github.com/user-attachments/assets/5b4a0d2c-df10-4ba1-82a0-bc0d1c9141c5">

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
SELECT
    ROUND(AVG(DATEDIFF(s2.start_date, s1.start_date))) AS average_days
FROM 
    subscriptions s1
        JOIN
    subscriptions s2 ON s1.customer_id = s2.customer_id AND s1.plan_id + 3 = s2.plan_id
WHERE s2.plan_id = 3;
```

<img width="117" alt="image" src="https://github.com/user-attachments/assets/eb8ebd3f-9bf7-42e1-bb3a-fc1bdd8275f2">

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
WITH cte_period_table AS (
    SELECT 
        CEIL(DATEDIFF(s2.start_date, s1.start_date) / 30) - 1 AS period,
        DATEDIFF(s2.start_date, s1.start_date) AS day_diff
    FROM
        subscriptions s1
            JOIN
        subscriptions s2 ON s1.customer_id = s2.customer_id AND s1.plan_id + 3 = s2.plan_id
    WHERE s2.plan_id = 3)
SELECT
    CONCAT((period * 30) + 1, '-', (period + 1) * 30) AS days,
    COUNT(day_diff) AS customer_count,
    ROUND(AVG(day_diff)) AS average_days
FROM cte_period_table
GROUP BY period
ORDER BY average_days;
```

<img width="317" alt="image" src="https://github.com/user-attachments/assets/8b79fe5a-bb77-4fc5-9160-c67364a168eb">

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
WITH cte_lead_plan AS (
    SELECT
        *,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date, plan_id) AS lead_plan
    FROM subscriptions)
SELECT
    COUNT(DISTINCT customer_id) AS customer_count
FROM cte_lead_plan
WHERE plan_id = 1 AND lead_plan = 2 AND YEAR(start_date) = '2020';
```

<img width="135" alt="image" src="https://github.com/user-attachments/assets/083ab92a-d93d-45cf-8f5d-c6b2a26f805f">

## C. Challenge Payment Question

The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

* monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
* upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
* upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
* once a customer churns they will no longer make payments

```sql
WITH cte_1 AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        start_date,
        price AS amount,
        LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS cutoff_date
    FROM 
        subscriptions 
            JOIN
        plans USING (plan_id)
    WHERE YEAR(start_date) = 2020 AND plan_name NOT IN ('trial', 'churn')),
cte_2 AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        start_date,
        COALESCE(cutoff_date, '2020-12-31') cutoff_date, 
        amount
    FROM cte_1)
SELECT * FROM cte_2;
```

<img width="533" alt="image" src="https://github.com/user-attachments/assets/feb780b5-47ba-4fe9-815e-f353f870ab89">

The is just a part of the table. There is a total of 1212 rows in the table.
