/*
=========================================================
Driver Burnout & Retention Analytics
File: 15_Indexes.sql
Database: PostgreSQL

Purpose:
Create indexes for:
- JOIN optimization
- WHERE filtering
- GROUP BY / aggregation support
- Date-based analysis
- Driver performance analysis
- Revenue analysis
- Burnout analysis
- Customer satisfaction
- Churn analysis
- Time-series analysis
=========================================================
*/

explain analyze
select * from trips

explain analyze
select driver_id from trips


--index on driver_id

create index if not exists idx_trips_driver_id
on trips(driver_id)

explain analyze
select driver_id from trips


-- indexon trip_date

create index if not exists idx_trips_trip_date
on trips(trip_date)

explain analyze
select driver_id from trips
where trip_date > '2025-01-02'

explain analyze
select driver_id from trips
where completed = true


-- driver_id,completed

create index if not exists idx_trips_driver_completed
on trips(driver_id, completed)

explain analyze
select driver_id from trips
where completed = true


explain analyze
select driver_id from earnings

-- index on earning driver id

create index if not exists idx_earnings_driver_id
on earnings(earning_date)

explain analyze
select total_income from earnings
where driver_id > 100000

-- index on earning date

create index if not exists idx_earning_date  
on earnings(earning_date)

-- index on driver_id, earning_date

create index if not exists idx_earning_driver_date
on earnings(driver_id,earning_date)

-- index on rating driver_id

create index if not exists idx_rating_driver_id
on ratings(driver_id)

-- ratings,driver_id

create index if not exists idx_rating_date
on ratings(driver_id, rating_date)

-- complaint driver id

create index if not exists idx_complaints_driver_id
on complaints(driver_id)

-- complaint_date,driver_id


create index if not exists idx_complaints_driver_date
on complaints(driver_id, complaint_date);


-- metrics driver date

create index if not exists idx_metrics_driver_date
on daily_driver_metrics(driver_id, activity_date);

-- city

create index if not exists  idx_drivers_city
on drivers(city);


-- vehicle_id


create index if not exists idx_drivers_vehicle
ON drivers(vehicle_id);



