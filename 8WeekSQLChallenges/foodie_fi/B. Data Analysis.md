## Data Analysis Questions

### How many customers has Foodie-Fi ever had?
```sql
SELECT COUNT(DISTINCT customer_id) FROM subscriptions;
```
This query returns the total count of unique customer IDs in the `subscriptions` table.

### What is the monthly distribution of trial plan start_date values for our dataset?
```sql
SELECT EXTRACT(MONTH FROM start_date) AS month, COUNT(1) AS number_of_trials
FROM subscriptions
WHERE plan_id = 0
GROUP BY EXTRACT(MONTH FROM start_date)
ORDER BY month;
```
This query groups the trial plan start dates by month and returns the count of trials for each month.

### What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
```sql
SELECT p.plan_name, COUNT(distinct s.customer_id)
FROM subscriptions s
LEFT JOIN plans p ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY p.plan_name
ORDER BY MAX(p.plan_id);
```
This query retrieves the plan start dates that occur after the year 2020 and provides a breakdown of the count of customers for each plan name.

### What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT 
    SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END)::numeric AS customer_churn,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND((SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END)::numeric / COUNT(DISTINCT customer_id)::numeric) * 100, 1) AS churn_percent
FROM subscriptions;
```
This query calculates the customer count and percentage of customers who have churned, rounded to 1 decimal place.

### How many customers have churned straight after their initial free trial? What percentage is this rounded to the nearest whole number?
```sql
WITH cte AS (
    SELECT
        customer_id,
        CASE WHEN plan_id = 0 AND LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date) = 4 THEN 1 ELSE 0 END AS straight_churn,
        CASE WHEN plan_id = 4 THEN 1 ELSE 0 END AS churned
    FROM subscriptions
)
SELECT
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(straight_churn) AS straight_churned,
    SUM(churned) AS total_churned,
    ROUND(SUM(straight_churn)::numeric / COUNT(DISTINCT customer_id)::numeric * 100) AS percent
FROM cte;
```
This query calculates the count and percentage of customers who have churned straight after their initial free trial, rounded to the nearest whole number.

### What is the number and percentage of customer plans after their initial free trial?
```sql
WITH cte AS (
    SELECT
        customer_id,
        plan_id,
        LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM subscriptions
)
SELECT
    MAX(p.plan_name),
    COUNT(1),
    ROUND(COUNT(1)::numeric / (SELECT COUNT(1) FROM cte WHERE plan_id = 0)::numeric * 100, 2)
FROM cte
LEFT JOIN plans p ON cte.next_plan = p.plan_id
WHERE cte.plan_id = 0
GROUP BY next_plan
ORDER BY MAX(p.plan_id);
```
This query provides the number and percentage breakdown of customer plans after their initial free trial.

### What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
WITH cte AS (
    SELECT
        customer_id,
        plan_id,
        start_date,
        LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
)
SELECT
    plan_id,
    COUNT(DISTINCT customer_id),
    ROUND((COUNT(DISTINCT customer_id)::numeric / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)::numeric) * 100, 2) AS percent_breakdown
FROM cte
WHERE (next_date IS NULL AND start_date < '2020-12-31')
    OR (next_date IS NOT NULL AND start_date < '2020-12-31' AND next_date > '2020-12-31')
GROUP BY plan_id;
```
This query calculates the customer count and percentage breakdown of all 5 plan_name values at the specified date.

### How many customers have upgraded to an annual plan in 2020?
```sql
WITH cte AS (
    SELECT
        customer_id,
        plan_id,
        LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan,
        LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
    FROM subscriptions
)
SELECT
    COUNT(DISTINCT customer_id)
FROM cte
WHERE next_plan = 3 AND EXTRACT(YEAR FROM next_date) = 2020;
```
This query calculates the number of customers who have upgraded to an annual plan in the year 2020.

### How many days on average does it take for a customer to upgrade to an annual plan from the day they join Foodie-Fi?
```sql
WITH cte AS (
    SELECT
        start_date,
        LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
    FROM subscriptions
    WHERE plan_id IN (0, 3)
)
SELECT
    ROUND(AVG(next_date - start_date), 2)
FROM cte
WHERE next_date IS NOT NULL;
```
This query calculates the average number of days it takes for a customer to upgrade to an annual plan from the day they join Foodie-Fi.

### Can you further breakdown this average value into 30-day periods?
```sql
WITH cte AS (
    SELECT
        start_date,
        LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
    FROM subscriptions
    WHERE plan_id IN (0, 3)
)
SELECT
    (next_date - start_date) / 30 AS bin,
    ((next_date - start_date) / 30 * 30)::text || ' - ' || (((next_date - start_date) / 30 * 30) + 30)::text || ' days' AS period,
    ROUND(AVG(next_date - start_date), 2) AS avg_tat
FROM cte
WHERE next_date IS NOT NULL
GROUP BY bin
ORDER BY bin;
```
This query further breaks down the average number of days into 30-day periods.

### How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
SELECT
    COUNT(DISTINCT s1.customer_id)
FROM subscriptions s1
JOIN subscriptions s2 ON s1.customer_id = s2.customer_id
    AND s1.plan_id - 1 = s2.plan_id
    AND s2.start_date > s1.start_date
    AND s2.plan_id = 1
    AND EXTRACT(YEAR FROM s2.start_date) = 2020;
```
This query calculates the number of customers who have downgraded from a pro monthly to a basic monthly plan in the year 2020.

