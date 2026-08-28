
"
	--- Driver Performance Analysis --

	Top 10 highest earning drivers।
	Top 10 drivers by completed trips।
	Drivers with the highest average customer rating।
	Drivers with the highest complaint count।
	Drivers with the highest cancellation rate।
	Drivers with the highest average daily online hours।
	Drivers with the highest average idle hours।
	Drivers with the highest average trip distance।
	Drivers with the longest average trip duration।
	Top drivers by average daily income।

"

-- 1. Top 10 highest earning drivers।

-- join earnings table and drivers table

select 
	d.driver_id,
	d.full_name,
	d.city,
	sum(e.total_income) as total_earnings
from drivers as d
join earnings as e
on d.driver_id = e.driver_id
group by d.driver_id, d.full_name, d.city
order by total_earnings desc
limit 10




-- 2. Top 10 drivers by completed trips

-- join drivers and trips table
-- check copleted = true


select 
	d.driver_id,
	d.full_name,
	count(*) as total_trips
from drivers as d
join trips as t
on d.driver_id = t.driver_id
where t.completed = true
group by
	d.driver_id,
	d.full_name
order by total_trips desc
limit 10



-- 3. Drivers with the highest average customer rating।
-- join drivers and ratings table
-- rating_id conciser avobe of 20 

select 
	d.driver_id,
	d.full_name,
	round(avg(r.customer_rating),2) as avg_rating
from drivers as d
join ratings as r
on d.driver_id = r.driver_id
group by
	d.driver_id,
	d.full_name
	having count(r.rating_id) >= 20
order by avg_rating desc
limit 10



-- 4. Drivers with the highest complaint count।


select 
	d.driver_id,
	d.full_name,
	count(c.complaint_id) as total_complain
from drivers as d
join complaints as c
on d.driver_id = c.driver_id
group by
	d.driver_id,
	d.full_name
order by total_complain desc
limit 10


--5. Drivers with the highest cancellation rate।



select 
	d.driver_id,
	d.full_name,
	count(case when t.cancelled = true then 1 end) as cancelled_trips,	
	count(*) as total_trips,
	round(count(case when t.cancelled = true then 1 end) * 100.0
	/ count(*),2) as cancelation_rate

--	round(cancelled_trips*100.0/total_trips) as cancelled_trips_2
from drivers as d
join trips as t
on d.driver_id = t.driver_id
group by
	d.driver_id,
	d.full_name
having count(*) >= 20
order by cancelation_rate desc
limit 10


-- 6. Drivers with the highest average daily online hours।
-- driver and daily_driver_metrics_table


select 
	d.driver_id,
	d.full_name,
	--to_char(ddm.activity_date, 'day') as daily,
	round(avg(ddm.online_hours),2) as avg_online_hourse
from drivers as d
join daily_driver_metrics as ddm
on d.driver_id = ddm.driver_id
group by 
	d.driver_id,
	d.full_name
	--daily
order by avg_online_hourse desc
limit 10


-- 7.Drivers with the highest average trip distance।


select 
	d.driver_id,
	d.full_name,
	round(avg(t.trip_distance_km),2) as avg_distance
from drivers as d
join trips as t
on d.driver_id = t.driver_id
where t.completed = true
group by
	d.driver_id,
	d.full_name
having count(*) >= 20
order by avg_distance desc
limit 10


-- 8. Drivers with the highest average idle hours।



select 
	d.driver_id,
	d.full_name,
	round(avg(ddm.idle_hours),2) as avg_idle_hourse
from drivers as d
join daily_driver_metrics as ddm
on d.driver_id = ddm.driver_id
group by 
	d.driver_id,
	d.full_name
order by avg_idle_hourse desc
limit 10



-- 9. Drivers with the longest average trip duration।


select 
	d.driver_id,
	d.full_name,
	round(avg(t.trip_duration_min),2) as avg_duration
from drivers as d
join trips as t
on d.driver_id = t.driver_id
where t.completed = true
group by
	d.driver_id,
	d.full_name
having count(*) >= 20
order by avg_duration desc
limit 10


-- 10. Top drivers by average daily income।


select 
	d.driver_id,
	d.full_name,
	round(avg(e.total_income),2) as avg_earnings
from drivers as d
join earnings as e
on d.driver_id = e.driver_id
group by d.driver_id, d.full_name
order by avg_earnings desc
limit 10




