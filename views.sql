/*
=========================================================
View: Driver Earnings Summary
Purpose:
Provides income-related KPIs for every driver.
=========================================================
*/



create or replace view driver_earnings as
select
	d.driver_id,
	d.full_name,
	d.city,
	sum(e.total_income) as total_income,
	round(avg(e.total_income),2) as avg_daily_income,
	sum(e.trip_income) as trip_income,
	sum(e.incentive) as total_incentive,
	sum(e.tips) as total_tips

from drivers as d
join earnings as e
on d.driver_id = e.driver_id
group by 
d.driver_id,
d.full_name,
d.city


/*
=========================================================
View: Driver Trip Performance
Purpose:
Summarizes trip-related KPIs.
=========================================================
*/

create or replace view driver_trip_performance as
select
	d.driver_id,
	d.full_name,
	count(*) filter (where t.completed) as completed_trips,
	count(*) filter (where t.cancelled) as cancelled_trips,
	count(*) as total_trips,
	round(count(*) filter(where t.cancelled)*100.0/nullif(count(*),0),2) as cancellation_rate,
	round(avg(t.trip_distance_km),2) as avg_trip_distance,
	round(avg(t.trip_duration_min),2) as avg_trip_duration
	
from drivers as d
join trips as t
on d.driver_id = t.driver_id
group  by
	d.driver_id,
	d.full_name


select * from driver_trip_performance


/*
=========================================================
View: Driver Activity Summary
Purpose:
Summarizes driver activity and productivity.
=========================================================
*/

create or replace view  driver_activity_summary as

select
	d.driver_id,
	d.full_name,
	round(avg(dm.online_hours),2) as avg_online_hours,
	round(avg(dm.idle_hours),2) as avg_idle_hours,
	round(avg(dm.rides_completed),2) as avg_daily_rides,
	round(avg(dm.login_count),2) as avg_login_count
from drivers as d
join daily_driver_metrics dm
on d.driver_id = dm.driver_id
group by 
	d.driver_id,
	d.full_name

select * from driver_activity_summary


/*
=========================================================
View: Driver Quality Summary
Purpose:
Summarizes customer satisfaction metrics.
=========================================================
*/

create or replace view driver_quality_summary as

select
	d.driver_id,
	d.full_name,
	round(avg(r.customer_rating),2) as average_rating,
	count(r.rating_id) as total_ratings,
	count(c.complaint_id) as total_complaints
from drivers as d
left join ratings as r
on d.driver_id = r.driver_id
left join complaints as c
on d.driver_id = c.driver_id
group by 
	d.driver_id,
	d.full_name

select  * from driver_quality_summary



/*
=========================================================
View: Revenue Summary
Purpose:
Revenue analysis by city and vehicle type.
=========================================================
*/


create or replace view revenue_summary as 
select
	d.city,
	v.vehicle_type,
	sum(e.trip_income) as trip_income,
	sum(e.incentive) as incentive,
	sum(e.total_income) as total_revenue,
	round(avg(e.total_income),2) as avg_driver_income

from earnings as e
join drivers as d
on e.driver_id = d.driver_id
join vehicles as v
on d.vehicle_id = v.vehicle_id
group by  
	d.city,
	v.vehicle_type

select * from revenue_summary



/*
=========================================================
View: Revenue Trend
Purpose:
Provides daily and monthly revenue trends.
=========================================================
*/

create or replace view revenue_trend as
select
	earning_date,
	date_trunc('month',earning_date) as revenue_month,
	sum(total_income) as daily_revenue
from earnings
group by
	earning_date,
	date_trunc('month',earning_date)

select * from revenue_trend




/*
=========================================================
View: Driver Revenue Performance
Purpose:
Revenue KPIs for every driver.
=========================================================
*/

create or replace view driver_revenue as 
select
	d.driver_id,
    d.full_name,
    d.city,
    v.vehicle_type,
	count(e.earning_id) as earning_days,
	sum(e.total_income) as total_income,
	round(avg(e.total_income),2) as avg_daily_income,
	sum(e.trip_income) as trip_income,
	sum(e.incentive) as total_incentive,
	sum(e.tips) as total_tips
from drivers as d
join earnings as e
on d.driver_id = e.driver_id
join vehicles as v
on v.vehicle_id = d.vehicle_id

group by 
	d.driver_id,
    d.full_name,
    d.city,
    v.vehicle_type

select * from driver_revenue



/*
=========================================================
View: Driver Activity & Burnout Metrics
Purpose:
Summarizes driver activity metrics used to calculate burnout.
=========================================================
*/


create or replace view driver_activity_burnout as
select
	d.driver_id,
	d.full_name,
	d.city,
	round(avg(dm.online_hours),2) as avg_online_hours,
	round(avg(dm.idle_hours),2) as avg_idle_hours,
	round(avg(dm.rides_completed),2) as avg_daily_rides,
	round(avg(r.customer_rating),2) as average_rating,
	count(distinct c.complaint_id) as total_complaints,
	round(avg(e.total_income),2) as avg_daily_income

from drivers as d
left join daily_driver_metrics as dm
on d.driver_id = dm.driver_id
left join earnings as e
on d.driver_id = e.driver_id
left join ratings as r
on d.driver_id = r.driver_id
left join complaints as c
on d.driver_id = c.driver_id
group by
d.driver_id,
d.full_name,
d.city;




select *from driver_activity_burnout



/*
=========================================================
View: Driver Burnout Score
Purpose:
Calculates burnout score for each driver.
=========================================================
*/


create or replace view driver_burnout_score as
select
*,
round((avg_online_hours * 3)
        +
        (avg_idle_hours * 2)
        +
        (total_complaints * 0.5)
        -
        (average_rating * 2)
        -
        (avg_daily_income / 100),
    2) AS burnout_score
from driver_activity_burnout


select * from driver_burnout_score



/*
=========================================================
View: Customer Satisfaction Summary
Purpose:
Provides customer satisfaction metrics for every driver.
=========================================================
*/


create or replace view customer_satisfaction as 

with rating_sammary as (

select
	driver_id,
	count(*) as total_ratings,
	round(avg(customer_rating),2) as average_rating
from ratings
group by driver_id

),

complaint_summary as (

select
	driver_id,
	count(*) as total_complaints,
	sum(case when resolved then 1 else 0 end ) as resolved_complaints
from complaints
group by driver_id
)

select
 	d.driver_id,
    d.full_name,
    d.city,
    v.vehicle_type,
	coalesce(r.total_ratings,0) as total_ratings,
coalesce(r.average_rating,0) as average_rating,
coalesce(c.total_complaints,0) as total_complaints,
coalesce(c.resolved_complaints,0) as resolved_complaints,
round(
coalesce(c.total_complaints,0)*100.0/
nullif(coalesce(r.total_ratings,0),0)
,2 
) as complaint_rate,

round(
coalesce(c.resolved_complaints,0)*100.0/
nullif(coalesce(c.total_complaints,0),0),
2
) as resolution_percentage

from drivers d
left join rating_sammary as r
on d.driver_id = r.driver_id

left join complaint_summary as c
on d.driver_id = c.driver_id

left join vehicles as v
on d.vehicle_id = v.vehicle_id;


select * from driver_burnout_score





/*
=========================================================
View: Rating Distribution
Purpose:
Provides rating distribution for dashboard charts.
=========================================================
*/




create or replace view rating_distribution as
	select
		customer_rating,
		count(*) as total_reviews,
		round(count(*) * 100.0 / 
		sum(count(*)) over(),2) as percentage

	from ratings
	group by customer_rating
	order by customer_rating desc


select * from rating_distribution


/*
=========================================================
View: Daily Revenue KPI
Purpose:
Provides daily revenue metrics for time-series analysis.
=========================================================
*/


create or replace view daily_revenue as
select	
	earning_date,
	sum(trip_income) as trip_income,
	sum(incentive) as incentive,
	sum(total_income) as total_revenue,
	count(distinct driver_id) as active_drivers,
	round(avg(total_income)) as avg_driver_income
from earnings
group by earning_date
order by earning_date


select * from daily_revenue



/*
=========================================================
View: Monthly Revenue KPI
Purpose:
Provides monthly revenue metrics for trend analysis.
=========================================================
*/

create or replace view monthly_revenue as
select
date_trunc('month', earning_date) as revenue_month,
sum(trip_income) as trip_income,
	sum(incentive) as incentive,
	sum(tips) as tips,
	sum(total_income) as total_revenue,
	count(distinct driver_id) as active_drivers,
	round(avg(total_income)) as avg_driver_income
from earnings
group by date_trunc('month', earning_date)
order by date_trunc('month', earning_date)

select * from monthly_revenue






