# Customer Journey

## Conversion Rates:
- 7 out of 8 customers (87.5%) converted from trial to a paid plan.
- Only 1 customer (Customer 11) churned immediately after the trial.

## Plan Preferences:
- 2 customers chose the Basic Monthly plan ($9.90)
- 3 customers opted for the Pro Monthly plan ($19.90)
- 3 customers selected the Pro Annual plan ($199.00)

## Upgrade Patterns:
- Customer 13 upgraded from Basic Monthly to Pro Monthly after 97 days.
- Customer 16 upgraded from Basic Monthly to Pro Annual after 136 days.
- Customer 19 upgraded from Pro Monthly to Pro Annual after 61 days.

## Churn:
- Customer 11 churned immediately after the trial.
- Customer 15 churned after using the Pro Monthly plan for 36 days.

## Long-term Retention:
- Customers 2, 16, and 19 showed commitment by choosing the Pro Annual plan.

## Quick Decision Making:
- Most customers decided on their plan immediately after the trial (7 days).
- Customer 2 went directly from trial to Pro Annual, showing high perceived value.

## Query:

```sql
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
```