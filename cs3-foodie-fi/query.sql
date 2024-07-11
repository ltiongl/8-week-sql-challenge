-- 8 Week SQL Challenge (https://8weeksqlchallenge.com/)
-- Case Study #3 - Foodie-Fi

USE foodie_fi;

-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

SELECT
	customer_id,
    plan_name,
    start_date,
    price
FROM
	plans 
		JOIN
	subscriptions USING (plan_id);
    
-- B. Data Analysis Questions
-- B.1. How many customers has Foodie-Fi ever had?

SELECT
	COUNT(DISTINCT customer_id) AS customer_count
FROM subscriptions;

-- B.2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

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

-- B.3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

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

-- B.4. What is the customer count, and percentage of customers who have churned, rounded to 1 decimal place?

SELECT
	SUM(CASE WHEN plan_name = 'churn' THEN 1 END) AS customer_count,
    ROUND(SUM(CASE WHEN plan_name = 'churn' THEN 1 END) / COUNT(DISTINCT customer_id) * 100, 1) AS chun_percentage
FROM 
	subscriptions 
		JOIN
	plans USING (plan_id);
    
-- B.5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

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
    
-- B.6. What is the number and percentage of customer plans after their initial free trial?

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

-- B.7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

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

-- B.8. How many customers have upgraded to an annual plan in 2020?

SELECT
	COUNT(customer_id) AS customer_count
FROM 
	subscriptions 
		JOIN
	plans USING (plan_id)
WHERE YEAR(start_date) = 2020 AND plan_name = 'pro annual';

-- B.9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

SELECT
	ROUND(AVG(DATEDIFF(s2.start_date, s1.start_date))) AS average_days
FROM 
	subscriptions s1
		JOIN
	subscriptions s2 ON s1.customer_id = s2.customer_id AND s1.plan_id + 3 = s2.plan_id
WHERE s2.plan_id = 3;
		
-- B.10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

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
    
-- B.11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

WITH cte_lead_plan AS (
	SELECT
		*,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date, plan_id) AS lead_plan
	FROM subscriptions)
SELECT
	COUNT(DISTINCT customer_id) AS customer_count
FROM cte_lead_plan
WHERE plan_id = 1 AND lead_plan = 2 AND YEAR(start_date) = '2020';

-- C. Challenge Payment Question
-- Create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
   -- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
   -- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
   -- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
   -- once a customer churns they will no longer make payments
   
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