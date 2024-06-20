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
	select pizza_id, string_to_table(toppings, ',')::int as ingredients
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



--	B. Runner and Customer Experience
--	1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--	had to mod with 53, as 1st of Jan 2021 was friday, making it 53rd week of 2019.
--	Another way to resolve it would have been calculating how far closest monday is, add that.
select
	extract('week' from r.registration_date)%53 as week1,
	count(r.runner_id)
FROM
	runners r 
group by
	week1
order by
	week1;


--	2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
--	This one was tricky in Postgres, check methods supported by extract
select
	runner_id,
	round(avg((extract(epoch from roc.pickup_time - coc.order_time) / 60)),2)
from
	customer_orders_clean coc
left join
	 runner_orders_clean roc 
on coc.order_id = roc.order_id 
where
	roc.cancellation is null
group by runner_id;


--	3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
--  limited data, it seems the time increases with count but correlation != Causation

with cte as (select order_id, max(order_time) as order_time, count(1) as count_pizza 
				from customer_orders_clean coc group by order_id)
select 
	cte.count_pizza, avg((extract(epoch from roc.pickup_time - cte.order_time) / 60))
from 
	runner_orders_clean roc 
inner join 
	cte
on roc.order_id = cte.order_id
where 
	roc.cancellation is null
group by
	cte.count_pizza;

	
--	4. What was the average distance travelled for each customer?
select
	coc.customer_id,
	round(avg(distance)::numeric, 2) as average_distance_travelled
from
	customer_orders_clean coc 
inner join
	runner_orders_clean roc 
on coc.order_id = roc.order_id
where 
	roc.cancellation is null
group by 
	coc.customer_id ;


--	5. What was the difference between the longest and shortest delivery times for all orders?
select 
	max(duration),
	min(duration),
	max(duration) - min(duration) as diff_delivery_time
from
	runner_orders_clean roc 
where 
	roc.cancellation is null;


--	6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
select
	roc.runner_id,
	roc.order_id ,
	round(max(roc.distance::numeric) / max(roc.duration::numeric/60),2) as avg_speed
from
	runner_orders_clean roc 
where 
	roc.cancellation is null
group by
	roc.runner_id, roc.order_id ;


--	7. What is the successful delivery percentage for each runner?
select 
	roc.runner_id,
	sum(case when roc.cancellation is null then 1
			else 0 end) as success_deliveries,
	count(roc.order_id) as total_deliveries,
	(sum(case when roc.cancellation is null then 1
			else 0 end)::numeric / count(roc.order_id)::numeric)*100 as success_delivery_percentage
from
	runner_orders_clean roc 
group by
	roc.runner_id;

	

--	C. Ingredient Optimisation
--	1. What are the standard ingredients for each pizza?
select 
	max(pn.pizza_name) ,
	string_agg(pt.topping_name, ',' )
from 
	pizza_recipes_norm prn
left join 
	pizza_toppings pt
	on prn.ingredients = pt.topping_id 
left join 
	pizza_names pn 
	on prn.pizza_id = pn.pizza_id 
group by
	prn.pizza_id ;

--	2. What was the most commonly added extra?
with ex_freq as (select
	string_to_table(extras,',')::int as extra,
	count(1) as freq
from
	customer_orders_clean coc 
group by extra)
select 
	pt.topping_name 
from
	ex_freq
left join
	pizza_toppings pt 
	on ex_freq.extra = pt.topping_id 
where 	
	freq = (select max(freq) from ex_freq);


--	3. What was the most common exclusion?
with ex_freq as (select
	string_to_table(exclusions,',')::int as exclusion,
	count(1) as freq
from
	customer_orders_clean coc 
group by exclusion)
select 
	pt.topping_name 
from
	ex_freq
left join
	pizza_toppings pt 
	on ex_freq.exclusion = pt.topping_id 
where 	
	freq = (select max(freq) from ex_freq);


--	4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--	Meat Lovers
--	Meat Lovers - Exclude Beef
--	Meat Lovers - Extra Bacon
--	Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- First, we need to normalize the extras and exclusions
-- cte_norm seperates the extras and exclusions into rows
-- makes it easier to join with pizza_toppings to get the names
-- Since we are using row_number, we can group the extras and exclusions back into a single row
-- n_ext_exc groups the extras and exclusions back into a single row
-- and also gets the names of the toppings
-- final select statement joins the pizza_names to get the pizza name
-- and filters out the duplicates
-- this is a bit complex, but it works (I think, I hope)
-- Takes care of the case where there are multiple extras and exclusions.
with cte_norm as (
select
	order_id, customer_id, pizza_id, 
	string_to_table(extras, ',')::int as extras, 
	string_to_table(exclusions, ',')::int as exclusions,
	row_number() over (partition by order_id, customer_id, pizza_id order by extras) as rn_ext,
	row_number() over (partition by order_id, customer_id, pizza_id order by exclusions) as rn_exc
from
	customer_orders_clean coc 
	)
, n_ext_exc as (
select 
	order_id, customer_id, pizza_id,
	string_agg(cte_norm.exclusions::text, ', ' order by cte_norm.exclusions) as exclusions,
	string_agg(cte_norm.extras::text, ', ' order by cte_norm.extras) as extras,
	string_agg(pt_exc.topping_name, ', ' order by cte_norm.exclusions) as exclusions_n,
	string_agg(pt.topping_name, ', ' order by cte_norm.extras) as extras_n,
	row_number() over (partition by order_id, customer_id, pizza_id) as rn_ext_exc
from
	cte_norm
left join
	pizza_toppings pt 
	on cte_norm.extras = pt.topping_id 
left join
	pizza_toppings pt_exc
	on cte_norm.exclusions = pt_exc.topping_id 
group by
	order_id, customer_id, pizza_id, rn_ext, rn_exc
	)
select
	pizza_name || 
    case when exclusions_n <> '' then ' - Exclude ' || exclusions_n else '' end ||
    case when extras_n <> '' then ' - Extra ' || extras_n else '' end as combined_description
	,coc.order_id, coc.customer_id, coc.pizza_id, coc.order_time,
	pn.pizza_name,
	n_ext_exc.exclusions_n,
	n_ext_exc.extras_n,
	n_ext_exc.rn_ext_exc
from
	customer_orders_clean coc 
left join
	n_ext_exc
	on coc.order_id = n_ext_exc.order_id
		and coc.customer_id = n_ext_exc.customer_id
		and coc.pizza_id = n_ext_exc.pizza_id
		and coalesce(coc.exclusions::text, '-'::text) = coalesce(n_ext_exc.exclusions::text, '-'::text)
		and coalesce(coc.extras::text, '-'::text) = coalesce(n_ext_exc.extras::text, '-'::text)
left join 	
	pizza_names pn
	on coc.pizza_id = pn.pizza_id 
where 
	coalesce (n_ext_exc.rn_ext_exc,1) = 1
order by 
	order_id;

select * from customer_orders_clean coc ;
	


--	5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--	For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- PENDING
with cte_norm as (
select
	order_id, customer_id, coc.pizza_id, coalesce(exclusions,'-') || ':' || coalesce(extras,'-') as key1,
	string_to_table(extras, ',') as extras, 
	string_to_table(exclusions, ',') as exclusions,
	row_number() over (partition by order_id, customer_id, coc.pizza_id order by extras) as rn_ext,
	row_number() over (partition by order_id, customer_id, coc.pizza_id order by exclusions) as rn_exc
from
	customer_orders_clean coc
	)
, toppings_list as (
select
	cte_norm.order_id, cte_norm.customer_id, cte_norm.pizza_id, key1,
	toppings,
	exclusions,
	extras,
	position(exclusions in toppings),
	string_to_table(replace(toppings, coalesce(exclusions, toppings) || ', ', '') || case when extras is not null then ', ' || extras else '' end, ',')::int as toppings_f
from
	cte_norm
left join
	pizza_recipes pr 
	on cte_norm.pizza_id = pr.pizza_id 
where 
	rn_ext = 1
	) 
--select order_id, customer_id, pizza_id, key1,  from toppings_list group by order_id, customer_id, pizza_id, key1;
, freq_topp as (
select 
--	*
	tl.order_id, tl.customer_id, tl.pizza_id, 
	tl.exclusions, tl.extras, 
	pt.topping_name, (key1) as key1,
	case when count(*)>1 then count(*)::text || 'x' || (topping_name) else (topping_name) end as freq_name
from 	
	toppings_list tl
left join
	pizza_toppings pt 
	on tl.toppings_f = pt.topping_id 
group by tl.order_id, tl.customer_id, tl.pizza_id, tl.exclusions, tl.extras, pt.topping_name, tl.key1
	) select * from freq_topp;
, ing_list_ex as (
select
	ft.order_id, ft.customer_id, ft.pizza_id, ft.key1,
	split_part(ft.key1, ':', 1) as extras,
    split_part(ft.key1, ':', 2) as exclusions,
	string_agg(distinct ft.freq_name, ', ' ) as ingredient_list_ex
from
	freq_topp ft
group by 
	ft.order_id, ft.customer_id, ft.pizza_id, ft.key1
	) select * from ing_list_ex;
,ing_list as (
select 
	prn.pizza_id,
	string_agg(pt.topping_name, ', ' order by pt.topping_name) as ingredient_list_def
from
	pizza_recipes_norm prn 
join
	pizza_toppings pt 
	on prn.ingredients = pt.topping_id 
group by
	prn.pizza_id
) --select * from ing_list_ex;
select 
	coc.order_id, coc.customer_id, coc.pizza_id, 
	coc.extras, coc.exclusions, 
--	iex.ingredient_list_ex,
--	idef.ingredient_list_def,
	coalesce(iex.ingredient_list_ex, idef.ingredient_list_def) as ingredient_list,
	coc.order_time
from
	customer_orders_clean coc 
left join
	ing_list_ex iex
	on coc.customer_id = iex.customer_id
		and coc.order_id = iex.order_id
		and coc.pizza_id = iex.pizza_id
		and coalesce(coc.exclusions,'-') || ':' || coalesce(coc.extras,'-')  = iex.key1
left join 
	ing_list idef
	on coc.pizza_id = idef.pizza_id
order by
	order_id, customer_id, pizza_id;

--Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes
select * from pizza_toppings pt ;






--	6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
-- PENDING
with cte as (
  select
  	order_id, customer_id, coc.pizza_id, coc.exclusions, extras,
    case
      when exclusions is not null then replace(replace(toppings, concat(',', replace(exclusions, ',', ',')), ''), ',', '')
      else toppings
    end as cleaned_toppings,
    case
      when extras is not null then concat(toppings, ',', extras)
      else toppings
    end as cleaned_toppings_with_extras
  from customer_orders_clean coc
  left join pizza_recipes pr on coc.pizza_id = pr.pizza_id
) select * from cte;
select
  topping,
  count(*) as topping_count
from (
  select
    trim(unnest(string_to_array(cleaned_toppings_with_extras, ','))) as topping
  from cte
  where cleaned_toppings_with_extras is not null
) t
group by topping
order by topping_count desc;



--	D. Pricing and Ratings
--	If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
select 
	sum(case when coc.pizza_id = 1 then 12
			else 10 end) as total_sales
from
	customer_orders_clean coc 
inner join
	runner_orders_clean roc 
on coc.order_id = roc.order_id 
where 	
	roc.cancellation is null;


--	What if there was an additional $1 charge for any pizza extras?
--	Add cheese is $1 extra

-- assuming each extra counts as a $1 and cheese is an additional $1
-- me when bored.
with norm_orders as (select 
	coc.customer_id,
	coc.order_id ,
	coc.pizza_id,
	case when coc.pizza_id = 1 then 12
			else 10 end as base_price,
	regexp_split_to_table(coalesce(coc.extras,'-1'), ',')::int as extras_n,
	row_number() over (partition by coc.order_id, coc.customer_id, coc.pizza_id order by extras) as rn_e
	from
		customer_orders_clean coc 
	where
		exists (select 1 from runner_orders_clean roc 
	        	where 
	        		coc.order_id = roc.order_id 
	        		and roc.cancellation is null)
	)
 , final_summary as (select 
	no1.order_id, no1.customer_id, no1.pizza_id,
	max(no1.base_price) as base_price1,
	sum(case when (no1.extras_n)<>-1 then 1 else 0 end) as count_extras,
	case when max(no1.extras_n)=4 then 1 else 0 end as cheese_cost
	from
		norm_orders no1
	group by
		no1.order_id, no1.customer_id, no1.pizza_id, no1.rn_e
	)
select
	sum(base_price1) + sum(count_extras) + sum(cheese_cost) sales_w_extras
from
	final_summary;


-- simplified, assuming any number of extras are a $1 and if cheese that's an additional $1
select 	
	sum(case when coc.pizza_id = 1 then 12
			else 10 end) as total_sales,
	sum(case when coc.extras like '%4%' then 2
			when coc.extras is not null then 1
			else 0 end) as extras_sales,
	sum(case when coc.pizza_id = 1 then 12 else 10 end) 
		+ sum(case when coc.extras like '%4%' then 2
			when coc.extras is not null then 1
			else 0 end) as sales_w_extras
from
	customer_orders_clean coc 
where
	exists (select 1 from runner_orders_clean roc 
        	where 
        		coc.order_id = roc.order_id 
        		and roc.cancellation is null);

-- PENDING --
--	The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.


--	Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--	customer_id
--	order_id
--	runner_id
--	rating
--	order_time
--	pickup_time
--	Time between order and pickup
--	Delivery duration
--	Average speed
--	Total number of pizzas
        	

--	If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
with runner_costs as (select sum(case when distance is not null then distance*0.3 else 0 end) as runner_cost
					from runner_orders_clean roc)
, piza_sales as (select
	sum(case when coc.pizza_id=1 then 12 else 10 end) as sales_pizza
from
	customer_orders_clean coc
where
	exists (select 1 from runner_orders_clean roc 
        	where 
        		coc.order_id = roc.order_id 
        		and roc.cancellation is null))
 select round(sales_pizza - runner_cost::numeric, 2) from piza_sales, runner_costs ;
