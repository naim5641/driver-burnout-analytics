/*
	
	----- Driver Burnout Analysis (21–30) ------
	Drivers working more than 10 hours/day on average।
	Drivers with the highest burnout score।
	Burnout score grouped by city।
	Burnout score grouped by vehicle type।
	Burnout vs average rating।
	Burnout vs complaints।
	Burnout vs earnings।
	Burnout vs completed rides।
	Drivers with the highest idle hours।
	Identify drivers who may leave within the next 30 days using a burnout rule।

*/


/*

1. Drivers working more than 10 hours/day on average

Business Question:
Which drivers work more than 10 hours per day on average?

Business Insight:
These drivers have a higher risk of fatigue and burnout.
The company can monitor them closely, recommend breaks,
or redesign shift schedules to improve driver well-being.
*/


select
	d.driver_id,
	d.full_name,
	d.city,
	round(avg(dm.online_hours),2) as avg_online_hours
from drivers as d
join daily_driver_metrics as dm
on d.driver_id = dm.driver_id
group by 
	d.driver_id,
	d.full_name,
	d.city
having avg(dm.online_hours) > 10
order by avg_online_hours desc


/*

2. Drivers with the highest burnout score

Business Insight:
Higher burnout scores indicate drivers who may become less productive,
receive more complaints, and eventually leave the platform.

Burnout Score =
(Avg Online Hours × 3)
+
(Total Complaints × 0.5)
-
(Avg Rating × 2)

*/


with burnout as (
select
	d.driver_id,
	d.full_name,
	round(avg(dm.online_hours),2) avg_online_hours,
	round(avg(r.customer_rating),2) avg_rating,
	count(c.complaint_id) complaints
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

left join ratings as r 
on d.driver_id = r.driver_id

left join complaints as c
on d.driver_id = c.driver_id


group by 
	d.driver_id,
	d.full_name
)

select
	*,
	round(
		(avg_online_hours*3)+(complaints*0.5)-(avg_rating*2),2
	) as burnout_score
from burnout
order by burnout_score desc
limit 20



/*

3. Burnout score grouped by city.

Business Insight:
Identifies cities where drivers experience higher burnout.
Operations teams can allocate incentives or recruit more drivers
in these locations.

*/




with burnout as (
select
	d.city,
	round(avg(dm.online_hours),2) avg_online_hours,
	round(avg(r.customer_rating),2) avg_rating,
	count(c.complaint_id) complaints
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

left join ratings as r 
on d.driver_id = r.driver_id

left join complaints as c
on d.driver_id = c.driver_id


group by 
	d.city
)

select
	*,
	round(
		(avg_online_hours*3)+(complaints*0.5)-(avg_rating*2),2
	) as burnout_score
from burnout
order by burnout_score desc


/*

4. Burnout score grouped by vehicle type.

Business Insight:
Determines whether a specific vehicle category is associated
with higher burnout.

*/




with burnout as (
select
	v.vehicle_type,
	round(avg(dm.online_hours),2) avg_online_hours,
	round(avg(r.customer_rating),2) avg_rating,
	count(c.complaint_id) complaints
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

left join ratings as r 
on d.driver_id = r.driver_id

left join complaints as c
on d.driver_id = c.driver_id

join vehicles as v
on d.vehicle_id = v.vehicle_id

group by 
	v.vehicle_type
)

select
	*,
	round(
		(avg_online_hours*3)+(complaints*0.5)-(avg_rating*2),2
	) as burnout_score
from burnout
order by burnout_score desc



/*
5. Burnout vs average rating.

Business Insight:
Examines whether burnout negatively affects customer ratings.

*/


SELECT
	d.driver_id,
	d.full_name,
	ROUND(AVG(dm.online_hours),2) avg_online_hours,
	ROUND(AVG(r.customer_rating),2) avg_rating
FROM drivers d

JOIN daily_driver_metrics dm
ON d.driver_id=dm.driver_id

JOIN ratings r
ON d.driver_id=r.driver_id

GROUP BY
	d.driver_id,
	d.full_name

ORDER BY avg_online_hours DESC;



/*
6. Burnout vs complaints.
Business Insight:
Drivers with longer working hours may receive more complaints.
*/



select
	d.driver_id,
	d.full_name,
	round(avg(dm.online_hours),2) avg_online_hours,
	count(c.complaint_id) complaints
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

left join complaints as c
on d.driver_id = c.driver_id

group by d.driver_id, d.full_name
order by avg_online_hours desc



/*

7. Burnout vs earnings.

Business Insight:
Shows whether working longer hours actually leads
to higher earnings or reaches a point of diminishing returns.
*/


select
	d.driver_id,
	d.full_name,
	round(avg(dm.online_hours),2) avg_online_hours,
	round(avg(e.total_income),2) as avg_earnings
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

join earnings as e
on e.driver_id = d.driver_id

group by d.driver_id, d.full_name
order by avg_online_hours desc






/*
8. Burnout vs completed rides.

Business Insight:
Evaluates whether drivers working longer hours
actually complete more rides.
*/




select
	d.driver_id,
	d.full_name,
	round(avg(dm.online_hours),2) avg_online_hours,
	round(avg(dm.rides_completed),2) as avg_rides_completed
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

group by d.driver_id, d.full_name
order by avg_online_hours desc




/*

9. Drivers with Highest Average Idle Hours.
Business Insight:
Drivers with excessive idle time may operate in low-demand
areas or inefficient time slots.

*/


select
	d.driver_id,
	d.full_name,
	round(avg(dm.idle_hours),2) as avg_idle_hours
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

group by d.driver_id, d.full_name
order by avg_idle_hours desc



/*
10. Drivers Likely to Leave Within the Next 30 Days.

Business Question:
Which drivers are at high risk of leaving
the platform within the next 30 days?

Business Rule:
Average Online Hours > 10
Average Rating < 4.2
Complaints >= 5
Business Insight:
These drivers should be prioritized for retention programs,
bonus incentives, coaching, or workload adjustments before
they churn.

*/



with cte as 
(
select
	d.driver_id,
	d.full_name,
	d.city,
	round(avg(dm.online_hours),2) avg_online_hours,
	round(avg(r.customer_rating),2) avg_rating,
	count(c.complaint_id) complaints
from drivers as d

join daily_driver_metrics as dm
on d.driver_id = dm.driver_id

left join ratings as r 
on d.driver_id = r.driver_id

left join complaints as c
on d.driver_id = c.driver_id

group by
	d.driver_id,
	d.full_name,
	d.city
)
select 
	*
from 
	cte
where avg_online_hours > 10 and avg_rating < 4.2 and complaints >= 5





