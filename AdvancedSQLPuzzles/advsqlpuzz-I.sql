-- Puzzle 1
select * from cart1 c1 full outer join cart2 c2 on c1.item=c2.item;
--
SELECT c1.item,c2.item
FROM cart1 c1 LEFT JOIN cart2 c2 ON c1.item=c2.item
UNION
SELECT c1.item,c2.item
FROM cart1 c1 right JOIN cart2 c2 ON c1.item=c2.item;


-- Puzzle 2
with recursive cte as (
	select EmployeeID, ManagerID, JobTitle, 0 as depth from employees
	where ManagerID is null
	union 
	select b.EmployeeID, b.ManagerID, b.JobTitle, cte.depth+1 as depth
	from employees b join cte on b.ManagerID = cte.employeeid
)
select * from cte;


-- Puzzle 4
select * from orders o
where DeliveryState = 'TX'
and CustomerID in (select distinct customerID from orders where deliverystate='CA');


-- Puzzle 5
select 
	CustomerID,
	max(case when type = 'Cellular' then PhoneNumber end) as cellular,
	max(case when type = 'Work' then PhoneNumber end) as work,
	max(case when type = 'Home' then PhoneNumber end) as Home
from
	PhoneDirectory
group by CustomerID;
--
WITH cte_PhoneNumbers AS
(
SELECT  CustomerID,
        PhoneNumber AS Cellular,
        NULL AS work,
        NULL AS home
FROM    PhoneDirectory
WHERE   Type = 'Cellular'
UNION
SELECT  CustomerID,
        NULL Cellular,
        PhoneNumber AS Work,
        NULL home
FROM    PhoneDirectory
WHERE   Type = 'Work'
UNION
SELECT  CustomerID,
        NULL Cellular,
        NULL Work,
        PhoneNumber AS Home
FROM    PhoneDirectory
WHERE   Type = 'Home'
)
SELECT  CustomerID,
        MAX(Cellular),
        MAX(Work),
        MAX(Home)
FROM    cte_PhoneNumbers
GROUP BY CustomerID;


-- Puzzle 6
SELECT * FROM WorkflowSteps
where completiondate is null 
and workflow in (select workflow from workflowsteps where completiondate is not null);
--
select workflow from workflowsteps w 
group by workflow 
having count(workflow)>count(completiondate);


-- Puzzle 7
select candidateid from candidates c 
where c.occupation in (select requirement from requirements r )
group by candidateid 
having count(*) = (select count(*) from requirements r );


-- Puzzle 8
SELECT workflow, case1+case2+case3
FROM WorkflowCases;


-- **int
-- Puzzle 9
with cte as (
	select employeeid, count(license) as cnt
	from employees
	group by employeeid 
),
cte_countw as (
	SELECT  a.EmployeeID AS EmployeeID_A,
        b.EmployeeID AS EmployeeID_B,
        COUNT(*) OVER (PARTITION BY a.EmployeeID, b.EmployeeID) AS CountWindow
	FROM    Employees a CROSS JOIN
        Employees b
	WHERE   a.EmployeeID <> b.EmployeeID and a.License = b.License
)
select 
	distinct cw.employeeid_a, cw.employeeid_b, cw.countwindow
from
	cte_countw cw
	join cte a on cw.employeeid_a = a.employeeid and a.cnt = cw.countWindow
	join cte b on cw.employeeid_b = b.employeeid and b.cnt = cw.countWindow;
	

-- Puzzle 10
-- MEDIAN
--Median
--SELECT
--        ((SELECT  IntegerValue
--        FROM    (
--                SELECT  TOP 50 PERCENT IntegerValue
--                FROM    SampleData
--                ORDER BY IntegerValue
--                ) a
--        ORDER BY IntegerValue desc
--        limit 1) +  --Add the Two Together
--        (SELECT IntegerValue
--        FROM (
--            SELECT  TOP 50 PERCENT IntegerValue
--            FROM    SampleData
--            ORDER BY IntegerValue DESC
--            ) a
--        ORDER BY IntegerValue asc
--        limit 1)
--        ) * 1.0 /2 AS Median;
       
-- Postgres median
 select PERCENTILE_CONT(0.5) within group(order by integervalue) from sampledata s ;
       

-- Puzzle 11
select 
	concat(t.testcase , t2.testcase, t3.testcase )
from testcases t 
cross join testcases t2 
cross join testcases t3 
where t.testcase<>t2.testcase and t2.testcase <> t3.testcase and t.testcase <> t3.testcase ;


-- Puzzle 12
with cte as (
select 
	workflow, ExecutionDate - lag(ExecutionDate) over (partition by workflow order by ExecutionDate) as diff
from processlog p 
)
select workflow, avg(diff)
from cte
where cte.workflow is not null
group by cte.workflow;


-- Puzzle 13
select 
	InventoryDate, QuantityAdjustment, sum(QuantityAdjustment) over (order by inventorydate)
from inventory i ;


-- Puzzle 14
select 
	workflow,
	case
		when count(distinct runstatus)=1 then max(runstatus)
		when count(distinct runstatus)>1 and sum(case when runstatus='Error' then 1 else 0 end)>0 then 'Intermediate'
		when count(distinct runstatus)=2 and min(runstatus) = 'Complete' AND max(runstatus) = 'Running' then 'Running'
		else null
	end as status
from
	ProcessLog
group by workflow;


-- Puzzle 15
select 
string_agg(string, ' ' order by sequencenumber)
from DMLTable;


-- Puzzle 16
SELECT
    LEAST(PlayerA, PlayerB) AS PlayerA,
    GREATEST(PlayerA, PlayerB) AS PlayerB,
    SUM(Score) AS TotalScore
FROM
    playerscores p 
GROUP BY
    LEAST(PlayerA, PlayerB),
    GREATEST(PlayerA, PlayerB);


-- Puzzle 17;
   ;
WITH RECURSIVE cte AS (
    SELECT ProductDescription, Quantity
    FROM Ungroup
    WHERE Quantity > 0

    UNION ALL

    SELECT ProductDescription, Quantity - 1
    FROM cte
    WHERE quantity >= 2
)
SELECT ProductDescription,1 as Quantity
FROM cte
ORDER BY ProductDescription;


-- Puzzle 18
with cte_gap as (SELECT  SeatNumber AS GapStart,
        LEAD(SeatNumber,1,0) OVER (ORDER BY SeatNumber) AS GapEnd,
        LEAD(SeatNumber,1,0) OVER (ORDER BY SeatNumber) - SeatNumber AS Gap
FROM    SeatingChart)
SELECT  GapStart + 1 AS GapStart,
        GapEnd - 1 AS GapEnd
FROM    cte_gap
WHERE Gap > 1;






-- Puzzle 19 
-- SKIP - Merge intervals SQL


-- Puzzle 21
WITH cte AS (
	select 	
		customerID, (State), avg(amount::numeric)
	from
		Orders
	group by customerid, orderdate, state
)
select o.state from orders o 
join cte c
on o.customerid = c.customerid and o.state=c.state
group by o.state 
having avg(o.amount::numeric)>=100; 

--
with cteAvg as (
	select customerID, state, avg(amount::numeric) as avgS
	from orders o 
	group by customerid, state, orderdate
)
	select state
	from cteAvg
	group by state 
	having min(avgS)>=100;



-- Puzzle 22
with cte as (
select 
	logmessage, workflow, sum(Occurrences) as occ
from processlog p 	
group by LogMessage, workflow
),
cte2 as (select logmessage, workflow, occ, dense_rank() over (partition by logmessage order by occ desc) as rn
	from cte )
select workflow, logmessage, occ
from cte2 where rn = 1;


-- Puzzle 23


