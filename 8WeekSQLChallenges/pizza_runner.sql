
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

insert into runner_orders_clean as
select order_id, 
		runner_id,
		case when pickup_time = 'null' then null
				else pickup_time 
		end as pickup_time,
		case when distance = 'null' then null
				else regexp_replace(distance, '[a-z]+', '') 
		end as distance,
		case when duration = 'null' then null
				else regexp_replace(duration, '[a-z]+', '') 
		end as duration,
		case when cancellation = '' then null
				when cancellation = 'null' then null
				else cancellation
		end as cancellation
from
	runner_orders ;

select * from runner_orders where duration REGEXP '[a-z]+' ;

		
	