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
with cte as (
select PERCENTILE_CONT(0.5) within group(order by score) as median from PlayerScores s )
select PlayerID, Score,
	case when score>=median then 1 else 2 end as rank
from playerscores cross join cte
order by rank;


-- Puzzle 24
with cte as (
select OrderID, CustomerID, OrderDate, Amount, State, row_number() over (order by orderid desc) as rn
from orders)
select *
from cte
where rn between 5 and 10
order by orderid;


-- Puzzle 25
with cte as (
select o.vendor, o.customerid , sum(count::numeric) as oPlaced
from orders o 
group by o.vendor, o.CustomerID),
ctern as (select  vendor, customerid, row_number() over (partition by customerid order by oPlaced desc) as rn 
from cte)
select vendor, customerid from ctern where rn =1;

;

--
with cte as (select o.vendor, o.customerid , sum(count::numeric) over (partition by o.vendor, o.CustomerID) as oPlaced
from orders o )
, ctern as (select customerid, vendor, oPlaced, row_number() over (partition by customerid order by oPlaced desc) as rn from cte)
select customerid, vendor from ctern where rn = 1;


-- Puzzle 26
select 	sum(case when year = extract(year from current_date) then amount else 0 end) as year0,
		sum(case when year = EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '1 YEAR') then amount else 0 end) as year1,
		sum(case when year = EXTRACT(YEAR FROM CURRENT_DATE - INTERVAL '2 YEAR') then amount else 0 end) as year2
from sales;


-- Puzzle 27
with cte as (select integervalue , row_number() over (partition by integervalue order by integervalue) as rn
from sampledata s) 
select integervalue from cte where rn = 1;


-- Puzzle 28 Note
WITH cte_Count AS
(
select RowNumber,
        TestCase,
        count(testcase) OVER (ORDER BY RowNumber) AS DistinctCount 	-- basically creating groups for each testcase. running count for each testcase
        															-- the first becomes 1, then 2, then 3 and so on. 
    FROM Gaps
)
SELECT  RowNumber,
        MAX(TestCase) OVER (PARTITION BY DistinctCount) AS TestCase -- selects the only testcase each group from above, and then assigns it
FROM    cte_Count
ORDER BY RowNumber;


-- Puzzle 29 Note
-- first get the rank for each status
-- works like this, got a series of numbers, get row number for each row, partitioned by the status, and orderer by this number series.
-- then subtract this row number from the number series.
-- series 1,2,3,4,5,6 status p,p,f,f,p,p row_number = 1,2,1,2,3,4
-- rank 0,0,2,2,2,2
-- group by on status and rank p,0 f,2 p,2 - 3 groups as required
with cte as (select StepNumber,
		status,
		row_number() over (partition by status order by stepnumber) as rn1,
		stepnumber - row_number() over (partition by status order by stepnumber) as rnk
from Groupings)
select 
	min(stepnumber), max(stepnumber), status,
	max(stepnumber) - min(stepnumber)+1 as count1
from cte
group by 
	status, rnk
order by rnk;		


-- Puzzle 31
-- Rank, where rn = 2
-- limit 1, where salary<(select max(sal) from table)


-- Puzzle 32
WITH cte as (
select 
	JobDescription,
        MAX(MissionCount) AS MaxMissionCount,
        MIN(MissionCount) AS MinMissionCount 
from personal p 
group by jobdescription)
select c.jobdescription, p1.spacemanid as mostexp , p2.spacemanid as minexp
from cte c
join personal p1 on p1.jobdescription = c.jobdescription and p1.missioncount = c.maxmissioncount
JOIN personal p2 on p2.jobdescription = c.jobdescription and p2.missioncount = c.minmissioncount;


-- Puzzle 33
with ctem as ( 
	select product, max(DaysToManufacture) as DaysToBuild
	from ManufacturingTimes mt
	group by product
) 
select 
	o.orderid,
	o.product,
	case
		when cte.daystobuild > o.DaysToDeliver then 'Ahead of Schedule'
		when cte.daystobuild < o.DaystoDeliver then 'Behind Schedule'
		when cte.daystobuild = o.DaystoDeliver then 'On Schedule'
	end as schedule
from Orders o
left join ctem cte on o.product = cte.product;


-- Puzzle 34
select  OrderID,
        CustomerID,
        Amount
from    Orders
except
select  OrderID,
        CustomerID,
        Amount
from    Orders
where   CustomerID = 1001 AND Amount::numeric = 50;


-- Puzzle 35
select 
	salesrepid
from orders o 
group by SalesRepID
having count(distinct SalesType) < 2;

-- find salesrep with salestype = 2 then not in.


-- Puzzle 36 
-- TSP - Sometime later.


-- Puzzle 37
select 
	*, dense_rank() over (order by Distributor, Facility, zone)
from GroupCriteria;


-- Puzzle 38 -- cross join build a map of the expected. then join
with cte_reg as (
select distinct region from regionsales),
cte_dist as (select distinct distributor from regionsales),
pair_r as (select region, distributor
from cte_reg cr
cross join cte_dist)
select pr.region, pr.distributor, case when rs.sales is null then 0 else rs.sales end as sales
from pair_r pr
left join regionsales rs on pr.region = rs.region and pr.distributor=rs.distributor
order by pr.distributor;


-- Puzzle 39 Skip


-- Puzzle 40 -- seems like a specific use case. 
select city
from sortorder s 
order by 
	 (case city when 'Atlanta' then 3
				when 'Baltimore' then 1
                when 'Chicago' then 4
                when 'Denver' then 2 end);
               

-- Puzzle 41 Some time later
               
               
-- Puzzle 42 " " "
               
               
-- Puzzle 43
select *, min(quantity) over (partition by customerid order by orderid)
from customerorders c ;


-- Puzzle 44
with cte as ( 
select customerid, balancedate, lead(balancedate) over (partition by customerid order by balancedate) - 1 as next1, amount
from balances)
select customerid, balancedate as startdate, case when next1 is null then '2099-12-31' else next1 end as enddate, amount
from cte
order by customerid, balancedate desc ;



-- Puzzle 45
with cte as (
select customerid, startdate, enddate, lead(startdate) over (partition by customerid order by StartDate) as nextstart, amount
from balances)
select customerid, startdate, enddate, amount
from cte
where enddate>=nextstart;


-- Puzzle 46
select accountid
from accountbalances a 	
group by accountid 
having sum(balance::numeric)<0;
--
select distinct accountid
from accountbalances a 
where balance::numeric<0
except
select distinct accountid 
from accountbalances a2 
where balance::numeric>0;
--
select accountid
from accountbalances a 
group by accountid
having max(balance::numeric)<0;


-- Puzzle 47
with times as (
	select ScheduleID, starttime as time1
	from schedule
	union 
	select ScheduleID, endtime as time1
	from schedule
	union 
	select scheduleid, StartTime as time1
	from activity
	union 
	select scheduleid, EndTime as time1
	from activity)
, act as (
	select t.scheduleid, t.time1, coalesce(a1.ActivityName, 'Work') as act
	from times t 
	left join activity a1 on t.scheduleid = a1.scheduleid and t.time1 = a1.starttime
)
, act_times as (
select scheduleid, act, time1 as starttime, lead(time1) over (partition by scheduleid order by time1) as endtime
from act t)
select * from act_times as t where endtime is not null
order by t.scheduleid, t.starttime;


-- Puzzle 48
select s.salesid
from sales s
join sales s1 on s.year-1 = s1.year and s.salesid = s1.salesid
join sales s2 on s.year-2 = s2.year and s.salesid = s2.salesid
where s.year = 2021;


-- Puzzle 49
with cte as (
	select lineorder, name, weight, sum(weight) over (order by lineorder) as cum_sum
	from elevatororder e
)
select name from cte 
where cum_sum<2000 
order by cum_sum desc
limit 1;


-- Puzzle 50
select *
from pitches;

with cte as(
	select batterid, pitchnumber, result,
			case when result='Ball' then 1 else 0 end as ball,
			case when result in ('Foul', 'Strike') then 1 else 0 end as strike
	from pitches p
)
, cte2 as (
	select batterid, pitchnumber, result,
		sum(ball) over (partition by batterid order by pitchnumber) as sumball,
		sum(strike) over (partition by batterid order by pitchnumber) as sumstrike
	from cte
)
, cte3 as (
	select batterid, pitchnumber, result, 
		lag(sumball,1,0) over (partition by batterid order by pitchnumber) as prev_ball, sumball,
		case   when    Result IN ('Foul','In-Play') and
                        LAG(sumstrike,1,0) over (partition by batterid order by pitchnumber) >= 3 THEN 2
                when    result = 'Strike' and sumstrike >= 2 THEN 2
                else    LAG(sumstrike,1,0) over (partition by batterid order by pitchnumber)
        end as prev_strike, sumstrike
	from cte2
) --select * from cte3;
select batterid, pitchnumber, result, concat(prev_ball, '-', prev_strike) as startpitchcount, 
		case when result = 'In Play' then result
			else concat(sumball, '-', (case when result = 'Foul' and sumstrike >= 3 then 2
											when result = 'Strike' and sumstrike>=2 then 3
											else sumstrike end))
			end as endpitchcount
from cte3;
           


-- Puzzle 53
with cte as (select least(primaryid, spouseid) as id1, greatest(primaryid, spouseid) as id2, dense_rank() over (order by least(primaryid, spouseid)) as rn
from spouses s
group by
    least(primaryid, spouseid),
    greatest(primaryid, spouseid))
select s.primaryid , s.spouseid , rn
from spouses s
join cte on s.primaryid = cte.id1 or s.spouseid = cte.id1
order by cte.rn;


-- Puzzle 54
with cte as (select l.ticketid , count(w.number) as cnt
from lotterytickets l 
left join winningnumbers w on l."number" = w."number" 
group by ticketid)
select  sum(case when cnt = (select count(1) from winningnumbers) then 100
			when cnt>0 then 10
		else 0 end) as amt
from cte;


-- Puzzle 55
--with cte as (select p.productname , p.quantity , p2.productname, p2.quantity 
-- )
select coalesce (p.productname, p2.productname),
		case when p.productname=p2.productname and p.quantity=p2.quantity then 'Matches in both table A and table B'
			when p.productname=p2.productname and p.quantity<>p2.quantity then 'Quantity in table A and table B do not match'
			when p.productname is null and p2.productname is not null then 'Product does not exist in table A'
			when p.productname is not null and p2.productname is null then 'Product does not exist in table B'
			end
from productsa p 
full outer join productsb p2 on p.productname = p2.productname;

