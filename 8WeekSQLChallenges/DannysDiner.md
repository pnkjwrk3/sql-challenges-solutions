# Dannys Diner Case Study Readme

## Introduction
This document provides a comprehensive guide to understanding and solving the case study questions related to Dannys Diner's sales data. The dataset contains information about customers, their orders, menu items, and membership details.

## Case Study Questions
Below are the questions posed along with SQL queries that provide solutions:

### 1. Total Amount Spent by Each Customer
```sql
SELECT
    customer_id,
    sum(price)
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;
```

### 2. Number of Days Each Customer Visited the Restaurant
```sql
SELECT customer_id, count(order_date)
FROM dannys_diner.sales
GROUP BY customer_id;
```

### 3. First Item Purchased by Each Customer
```sql
SELECT *
FROM (
    SELECT
        s.customer_id,
        m.product_name,
        row_number() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m ON s.product_id = m.product_id
) a
WHERE rn = 1;
```
### 4. Most Purchased Item on the Menu and its Frequency
```sql
WITH cnt AS (
    SELECT
        s.product_id,
        m.product_name,
        count(s.product_id) AS c1
    FROM dannys_diner.sales s
    JOIN dannys_diner.menu m ON s.product_id = m.product_id
    GROUP BY s.product_id, m.product_name
), cmax AS (
    SELECT *
    FROM cnt
    ORDER BY c1 DESC
    LIMIT 1
)
SELECT s.customer_id, count(s.product_id)
FROM dannys_diner.sales s, cmax
WHERE s.product_id = cmax.product_id
GROUP BY s.customer_id;
```
### 5. Most Popular Item for Each Customer
```sql
WITH ct1 AS (
    SELECT
        s.customer_id,
        s.product_id,
        dense_rank() OVER (PARTITION BY s.customer_id ORDER BY count(s.product_id) DESC) AS rn
    FROM dannys_diner.sales s
    GROUP BY s.customer_id, s.product_id
)
SELECT ct1.customer_id, m.product_name
FROM ct1
JOIN dannys_diner.menu m ON ct1.product_id = m.product_id
WHERE ct1.rn = 1
ORDER BY ct1.customer_id;
```
### 6. Item Purchased First by Each Customer After Joining Membership
```sql
WITH ct1 AS (
    SELECT
        s.customer_id,
        s.product_id,
        s.order_date,
        dense_rank() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rn
    FROM dannys_diner.sales s
    JOIN dannys_diner.members m ON s.customer_id = m.customer_id
    WHERE s.order_date >= m.join_date
)
SELECT ct1.customer_id, ct1.order_date, m.product_name
FROM ct1
JOIN dannys_diner.menu m ON ct1.product_id = m.product_id
WHERE ct1.rn = 1;
```
### 7. Item Purchased Just Before Each Customer Became a Member
```sql
WITH ct1 AS (
    SELECT
        s.customer_id,
        s.product_id,
        s.order_date,
        dense_rank() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rn
    FROM dannys_diner.sales s
    JOIN dannys_diner.members m ON s.customer_id = m.customer_id
    WHERE s.order_date < m.join_date
)
SELECT ct1.customer_id, ct1.order_date, m.product_name
FROM ct1
JOIN dannys_diner.menu m ON ct1.product_id = m.product_id
WHERE ct1.rn = 1;
```
### 8. Total Items and Amount Spent for Each Member Before They Became a Member
```sql
WITH ct1 AS (
    SELECT
        s.customer_id,
        s.product_id,
        s.order_date
    FROM dannys_diner.sales s
    JOIN dannys_diner.members m ON s.customer_id = m.customer_id
    WHERE s.order_date < m.join_date
)
SELECT
    ct1.customer_id,
    count(DISTINCT ct1.product_id) AS total_items,
    sum(men.price) AS total_amount
FROM ct1
JOIN dannys_diner.menu men ON ct1.product_id = men.product_id
GROUP BY ct1.customer_id;
```
### 9. Points Earned by Each Customer (Considering $1 Spent Equates to 10 Points with 2x Points Multiplier for Sushi)
```sql
SELECT
    ct1.customer_id,
    sum(CASE WHEN men.product_name='sushi' THEN men.price*20 ELSE men.price*10 END) AS points
FROM dannys_diner.sales ct1
JOIN dannys_diner.menu men ON ct1.product_id = men.product_id
GROUP BY ct1.customer_id;
```
### 10. Points Earned by Customer A and B in the First Week After Joining (including Join Date) with 2x Points Multiplier on All Items
```sql
SELECT
    ct1.customer_id,
    sum(CASE 
        WHEN ct1.order_date < m.join_date + 7 AND ct1.order_date >= m.join_date THEN men.price*20
        ELSE CASE 
            WHEN men.product_name='sushi' THEN men.price*20
            ELSE men.price*10 
            END
        END) AS points
FROM dannys_diner.sales ct1
JOIN dannys_diner.menu men ON ct1.product_id = men.product_id
JOIN dannys_diner.members m ON ct1.customer_id = m.customer_id
WHERE ct1.order_date <= '2021-01-31'
GROUP BY ct1.customer_id;
```