SET search_path = foodie_fi;

-- Customer journey
--	Conversion Rates:
--		7 out of 8 customers (87.5%) converted from trial to a paid plan.
--		Only 1 customer (Customer 11) churned immediately after the trial.
--	Plan Preferences:
--		2 customers chose the Basic Monthly plan ($9.90)
--		3 customers opted for the Pro Monthly plan ($19.90)
--		3 customers selected the Pro Annual plan ($199.00)
--	Upgrade Patterns:
--		Customer 13 upgraded from Basic Monthly to Pro Monthly after 97 days.
--		Customer 16 upgraded from Basic Monthly to Pro Annual after 136 days.
--		Customer 19 upgraded from Pro Monthly to Pro Annual after 61 days.
--	Churn:
--		Customer 11 churned immediately after the trial.
--		Customer 15 churned after using the Pro Monthly plan for 36 days.
--	Long-term Retention:
--		Customers 2, 16, and 19 showed commitment by choosing the Pro Annual plan.
--	Quick Decision Making:
--		Most customers decided on their plan immediately after the trial (7 days).
--		Customer 2 went directly from trial to Pro Annual, showing high perceived value.

select 
	s.customer_id ,
	p.plan_name ,
	p.price,
	s.start_date ,
	start_date - lag(start_date, 1) over (partition by customer_id order by start_date) as days_to_change,
	case when plan_name = 'trial' and lead(plan_name) over (partition by customer_id order by start_date) = 'churn' then 'no convert'
		else 'convert' end as convert_h
from 
	subscriptions s 
left join
	"plans" p 
	on s.plan_id = p.plan_id 
where 
	s.customer_id in (1,2,11,13,15,16,18,19)
order by 		
	s.customer_id, s.start_date ;


--B. Data Analysis Questions
--
--How many customers has Foodie-Fi ever had?
select 
	count(distinct customer_id)
from
	subscriptions s;


--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select
	extract(month from s.start_date) as month_,
	count(1) as number_of_trials
from
	subscriptions s 
where
	s.plan_id = 0
group by 
	extract(month from s.start_date)
order by
	month_;


--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select 
	p.plan_name ,
	count(distinct s.customer_id)
from
	subscriptions s 
left join
	"plans" p 
	on s.plan_id = p.plan_id 
where extract(year from s.start_date) > 2020
group by p.plan_name 
order by max(p.plan_id) ;



--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select 
	sum(case when s.plan_id = 4 then 1 else 0 end)::numeric as customer_churn, 
	count(distinct s.customer_id) as total_customers,
	round((sum(case when s.plan_id = 4 then 1 else 0 end)::numeric / count(distinct s.customer_id)::numeric)*100, 2) as churn_percent
from
	subscriptions s ;



--How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte as (select
	s.customer_id,
	case when s.plan_id = 0 and lead(s.plan_id, 1) over (partition by s.customer_id order by s.start_date) = 4 then 1
		else 0 end as straight_churn,
	case when s.plan_id = 4 then 1 else 0 end as churned
from
	subscriptions s )
select 
	count(distinct customer_id) as total_customers,
	sum(straight_churn) as straight_churned,
	sum(churned) as total_churned,
	round(sum(straight_churn)::numeric/count(distinct customer_id)::numeric*100,2) as percent_
from 
	cte ;


--What is the number and percentage of customer plans after their initial free trial?
with cte as (select
	s.customer_id,
	s.plan_id,
	lead(s.plan_id, 1) over (partition by s.customer_id order by s.start_date) next_plan
from
	subscriptions s)
select
	max(p.plan_name ),
	count(1),
	round(count(1)::numeric/(select count(1) from cte where plan_id=0)::numeric * 100,2)
from
	cte
left join
	"plans" p 
	on cte.next_plan = p.plan_id
where cte.plan_id = 0
group by
	next_plan
order by
	max(p.plan_id) ;



--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- find those customers who didnt upgrade the plan
with cte as (select
	s.customer_id,
	s.plan_id,
	s.start_date,
	lead(s.start_date, 1) over (partition by s.customer_id order by s.start_date) next_date
from
	subscriptions s
where	
	s.start_date <= '2020-12-31')
select 	
	plan_id,
	count(distinct customer_id),
	round((count(distinct customer_id)::numeric/(select count(distinct customer_id) from subscriptions)::numeric)*100,2) as percent_breakdown
from
	cte
where 
	(next_date is null and start_date < '2020-12-31')
	or (next_date is not null and start_date < '2020-12-31' and next_date > '2020-12-31')
group by
	plan_id;



--How many customers have upgraded to an annual plan in 2020?
with cte as (select 
	s.customer_id,
	s.plan_id,
	lead(s.plan_id,1) over (partition by customer_id order by start_date) as next_plan,
	lead(s.start_date,1) over (partition by customer_id order by start_date) as next_date
from
	subscriptions s )
select
	count(distinct customer_id)
from 
	cte
where
	cte.next_plan = 3 and extract(year from cte.next_date) = 2020;


select * from "plans" p ;



--How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with cte as (select
	s.start_date,
	lead(s.start_date, 1) over (partition by customer_id order by start_date) as next_date
from
	subscriptions s 
where s.plan_id in (0,3))
select 
	round(avg(cte.next_date - cte.start_date),2)
from
	cte
where 
	cte.next_date is not null;

-- using self join
select
	round(avg(s2.start_date - s1.start_date),2)
from
	subscriptions s1
join
	subscriptions s2
	on s1.customer_id = s2.customer_id 
	and s1.plan_id+3 = s2.plan_id 
	and s2.plan_id = 3;


--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with cte as (select
	s.start_date,
	lead(s.start_date, 1) over (partition by customer_id order by start_date) as next_date
from
	subscriptions s 
where s.plan_id in (0,3))
select 
	(cte.next_date - cte.start_date)/30 as bin,
	((cte.next_date - cte.start_date)/30 * 30)::text || ' - ' || (((cte.next_date - cte.start_date)/30 * 30) + 30)::text || ' days',
	round(avg(cte.next_date - cte.start_date),2) as avg_tat
from
	cte
where 
	cte.next_date is not null
group by 
	bin
order by bin;




--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select
	count(distinct s1.customer_id)
from
	subscriptions s1
join
	subscriptions s2
	on s1.customer_id = s2.customer_id 
	and s1.plan_id - 1 = s2.plan_id 
	and s2.start_date > s1.start_date
	and s2.plan_id = 1
	and extract(year from s2.start_date) = 2020;

-- using CTE, window functions
with cte as (select
	s.customer_id,
	s.start_date,
	s.plan_id,
	lead(s.plan_id, 1) over (partition by customer_id order by start_date) as next_plan
from
	subscriptions s
where 
	s.plan_id in (1,2)
	and s.start_date<='2020-12-31'
)
select 
	count(distinct customer_id)
from
	cte
where cte.plan_id = 2 and cte.next_plan = 1;


