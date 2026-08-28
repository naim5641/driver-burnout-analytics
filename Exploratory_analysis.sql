
-- Total drivers

SELECT COUNT(*) AS total_drivers
FROM drivers;

-- Total trips

SELECT COUNT(*) AS total_trips
FROM trips;



-- Completed vs Cancelled Trips


SELECT
    completed,
    COUNT(*) AS total_trips
FROM trips
GROUP BY completed;


-- Completion Rate


SELECT
ROUND(
SUM(CASE WHEN completed THEN 1 ELSE 0 END)*100.0/COUNT(*),2)
AS completion_rate
FROM trips;

-- Total Revenue

SELECT
ROUND(SUM(total_income),2) AS total_revenue
FROM earnings;


-- Average Trip Fare

SELECT
ROUND(AVG(fare),2) AS avg_fare
FROM trips;

-- Average Trip Distance

SELECT
ROUND(AVG(trip_distance_km),2) AS avg_distance
FROM trips;

-- Average Trip Duration

SELECT
ROUND(AVG(trip_duration_min),2) AS avg_duration
FROM trips;


-- Driver Distribution by City

SELECT
city,
COUNT(*) AS total_drivers
FROM drivers
GROUP BY city
ORDER BY total_drivers DESC;



-- Vehicle Distribution

SELECT
v.vehicle_type,
COUNT(*) AS total_drivers
FROM drivers d
JOIN vehicles v
ON d.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_type
ORDER BY total_drivers DESC;


-- Driver Status Distribution 

SELECT
driver_status,
COUNT(*) AS total
FROM drivers
GROUP BY driver_status;

-- Average Driver Rating

SELECT
ROUND(AVG(customer_rating),2) AS average_rating
FROM ratings;

-- Rating Distribution

SELECT
customer_rating,
COUNT(*) AS total
FROM ratings
GROUP BY customer_rating
ORDER BY customer_rating DESC;


-- Complaint Distribution

SELECT
complaint_type,
COUNT(*) AS total
FROM complaints
GROUP BY complaint_type
ORDER BY total DESC;



-- Complaint Resolution Rate

SELECT
resolved,
COUNT(*) AS total
FROM complaints
GROUP BY resolved;

-- Average Daily Online Hours

SELECT
ROUND(AVG(online_hours),2) AS avg_online_hours
FROM daily_driver_metrics;


-- Average Daily Rides

SELECT
ROUND(AVG(rides_completed),2) AS avg_daily_rides
FROM daily_driver_metrics;


-- Churn Distribution


SELECT
churned,
COUNT(*) AS total_drivers
FROM churn_labels
GROUP BY churned;


-- Monthly Trip Trend



SELECT
DATE_TRUNC('month',trip_date) AS month,
COUNT(*) AS total_trips
FROM trips
GROUP BY month
ORDER BY month;

-- Monthly Revenue Trend

SELECT
DATE_TRUNC('month',earning_date) AS month,
ROUND(SUM(total_income),2) AS revenue
FROM earnings
GROUP BY month
ORDER BY month;

