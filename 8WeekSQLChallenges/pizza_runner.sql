SET search_path = pizza_runner;


-- Data cleaning for customer_orders
select * from customer_orders;

drop table if exists customer_orders_clean;
create table customer_orders_clean as
select order_id, 
		customer_id,
		pizza_id,
		case when exclusions = 'null' then null
				when exclusions = '' then null
				else exclusions 
		end as exclusions,
		case when extras = 'null' then null
				when extras = '' then null
				else extras 
		end as extras,
		order_time
from
	customer_orders;

select * from customer_orders_clean;


-- Data cleaning for runner_orders
select * from runner_orders;

drop table if exists runner_orders_clean;
CREATE TABLE runner_orders_clean (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" REAL,
  "duration" INTEGER,
  "cancellation" VARCHAR(23)
);

insert into runner_orders_clean
select order_id, 
		runner_id,
		case when pickup_time = 'null' then null
				else pickup_time 
		end as pickup_time,
		case when distance = 'null' then null
				else cast(regexp_replace(distance, '[a-z]+', '') as real)
		end as distance,
		case when duration = 'null' then null
				else cast(regexp_replace(duration, '[a-z]+', '') as int) 
		end as duration,
		case when cancellation = '' then null
				when cancellation = 'null' then null
				else cancellation
		end as cancellation
from
	runner_orders ;

select * from runner_orders_clean ;


-- Formatting columns data types
ALTER TABLE pizza_runner.runner_orders_clean ALTER COLUMN pickup_time TYPE timestamp USING pickup_time::timestamp;


-- normalizing pizza_recipes
select * from pizza_recipes pr;

select pizza_id, string_to_table(toppings, ',') from pizza_recipes pr;

drop table if exists pizza_recipes_norm;
create table pizza_recipes_norm as
	select pizza_id, string_to_table(toppings, ',')
	from pizza_recipes pr ;

		
-- that should do it for now



-- 	A. Pizza Metrics
--	1. How many pizzas were ordered?	14
select 
	count(order_id)
from
	customer_orders_clean coc; 

--	2. How many unique customer orders were made?	10
select
	count(distinct(order_id))
from
	customer_orders_clean coc; 


--	3. How many successful orders were delivered by each runner?
select 
	runner_id,
	count(order_id) as order_count
from 
	runner_orders_clean roc 
where
	roc.cancellation is null
group by 
	roc.runner_id;


--	4. How many of each type of pizza was delivered?
select 
	max(pn.pizza_name) ,
	count(1)
from
	runner_orders_clean roc 
inner join
	customer_orders_clean co 
on roc.order_id =co.order_id 
inner join
	pizza_names pn 
on co.pizza_id = pn.pizza_id 
where 
	roc.cancellation is null
group by co.pizza_id ;


--	5. How many Vegetarian and Meatlovers were ordered by each customer?
select 
	coc.customer_id, pn.pizza_name, count(1) 
from
	customer_orders_clean coc 
inner join
	pizza_names pn 
on coc.pizza_id = pn.pizza_id 
group by 
	coc.customer_id, pn.pizza_name 
order by 
	coc.customer_id ;


--	6. What was the maximum number of pizzas delivered in a single order?
select 
	coc.order_id, count(order_id)
from 
	customer_orders_clean coc 
group by 
	coc.order_id
order by
	count(order_id) desc
limit 1;



--	7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select 
	customer_id,
	sum(case when exclusions is not null or extras is not null then 1 else 0 end) as change1,
	sum(case when extras is null and exclusions is null then 1 else 0 end) as nochange
from 
	customer_orders_clean coc 
inner join
	runner_orders_clean roc 
on coc.order_id = roc.order_id 
where	
	roc.cancellation is null
group by
	customer_id ;


--	8. How many pizzas were delivered that had both exclusions and extras?
select 
--	customer_id,
	sum(case when exclusions is not null and extras is not null then 1 else 0 end) as both_exc_and_ext
--	sum(case when extras is null and exclusions is null then 1 else 0 end) as nochange
from 
	customer_orders_clean coc 
inner join
	runner_orders_clean roc 
on coc.order_id = roc.order_id 
where	
	roc.cancellation is null
--group by
--	customer_id ;


--	9. What was the total volume of pizzas ordered for each hour of the day?
select 
	extract(hour from coc.order_time) as hour1, count(order_id) as pizzaCount
from
	customer_orders_clean coc 
group by
	hour1
order by
	hour1;
	


--	10. What was the volume of orders for each day of the week?
select 
--	extract(dow from coc.order_time) as day1, 
	to_char(order_time, 'Day') as day1,
	count(order_id) as pizzaCount
from
	customer_orders_clean coc 
group by
	day1
order by 	
	pizzaCount desc;
	

