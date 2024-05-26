-- Source: https://www.interviewquery.com/questions/employee-salaries

-- Given a employees and departments table, select the top 3 departments with at least ten employees
-- and rank them according to the percentage of their employees making over 100K in salary.

-- employees table
-- Columns	        Type
-- id	            INTEGER
-- first_name	    VARCHAR
-- last_name	    VARCHAR
-- salary	        INTEGER
-- department_id	INTEGER

-- departments table
-- Columns	Type
-- id	INTEGER
-- name	VARCHAR

-- Output:
-- Column	            Type
-- percentage_over_100k	FLOAT
-- department_name	    VARCHAR
-- number_of_employees	INTEGER

-- Notes:
-- Used average to count the percentage of employees making over 100K in salary.
-- group by department name and then check if the number of employees is greater than or equal to 10.
-- Order by the percentage of employees making over 100K in salary and limit to 3.

select d.name as department_name, 
    avg(case when e.salary>100000 then 1 else 0 end) as percentage_over_100k,
    count(1) as number_of_employees
from employees e 
    left join departments d
    on e.department_id = d.id
group by d.name
    having count(e.id)>=10
order by avg(case when e.salary>100000 then 1 else 0 end)
    limit 3
