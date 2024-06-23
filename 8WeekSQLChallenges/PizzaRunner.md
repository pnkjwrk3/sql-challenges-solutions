# Pizza Runner Case Study Readme

## Introduction
This document provides a comprehensive guide to understanding and solving the case study questions related to Pizza Runner's delivery data. The dataset contains information about customers, their orders, and delivery details.

# Challenges
- For customer_orders, clean up the data for exclusions and extras columns. handle nulls, and data types
- For runner_orders, clean up the data for distance and duration columns. handle nulls, and data types 

## Case Study Questions

This case study turned out to be much more challenging than the previous one. The questions were more complex and required a deeper understanding of the data and SQL functions. Won't be able to provide the answers here as they are quite lengthy and detailed, feel free to look into [pizza_runner.sql](./pizza_runner.sql) file. However, I will provide a brief overview of the questions and the approach I took to solve them.

### Data Cleaning
Many of the questions required cleaning up the data in the customer_orders and runner_orders tables. This involved handling null values, converting data types, and cleaning up the exclusions and extras columns.

pizza_recipes table was also normalized to split the ingredients into separate rows.

### Pizza Metrics
Pretty much all the questions in this section required calculating various metrics related to the orders, such as the total number of orders, the average order value, and the most popular pizza.

Mostly used joins and aggregation functions to calculate these metrics.


### Runner and Customer Experience
Same as the previous section, these questions required calculating various metrics related to the runners and customers, such as the average delivery time, the most popular runner, and the most loyal customer.

Used joins and aggregation functions to calculate these metrics.


### Ingredient Optimisation
This section was tricky as it required to list the ingredients for pizzas, and also find the list of ingredients for each order with extras and exclusions removed.

Used a combination of joins, subqueries, windows, and string functions to achieve this. Lots of group by, string_to_array, and array_agg functions were used. One key insight was to use the combination of pizza_id, extras, exclusions to uniquely identify each pizza order. Exists, Union all and CTEs were also used to simplify the queries.


### Pricing and Ratings
This section was not as complex as the previous one. It required calculating the total revenue, with conditions on extras for each order. Calculating the average rating for each runner was skipped.