CREATE OR REPLACE VIEW vw_driver_master AS

WITH trip_summary AS (
    SELECT
        driver_id,
        COUNT(*) AS total_trips,
        COUNT(*) FILTER (WHERE completed = TRUE) AS completed_trips,
        COUNT(*) FILTER (WHERE cancelled = TRUE) AS cancelled_trips,

        ROUND(
            COUNT(*) FILTER (WHERE cancelled = TRUE) * 100.0
            / NULLIF(COUNT(*), 0),
            2
        ) AS cancellation_rate,

        ROUND(
            AVG(trip_distance_km) FILTER (WHERE completed = TRUE),
            2
        ) AS avg_trip_distance_km,

        ROUND(
            AVG(trip_duration_min) FILTER (WHERE completed = TRUE),
            2
        ) AS avg_trip_duration_min

    FROM trips
    GROUP BY driver_id
),

earnings_summary AS (
    SELECT
        driver_id,
        ROUND(SUM(total_income), 2) AS total_earnings,
        ROUND(AVG(total_income), 2) AS avg_daily_income
    FROM earnings
    GROUP BY driver_id
),

rating_summary AS (
    SELECT
        driver_id,
        ROUND(AVG(customer_rating), 2) AS avg_rating,
        COUNT(rating_id) AS total_ratings
    FROM ratings
    GROUP BY driver_id
),

complaint_summary AS (
    SELECT
        driver_id,
        COUNT(complaint_id) AS total_complaints
    FROM complaints
    GROUP BY driver_id
),

daily_summary AS (
    SELECT
        driver_id,

        ROUND(AVG(online_hours), 2) AS avg_online_hours,

        ROUND(AVG(idle_hours), 2) AS avg_idle_hours,

        ROUND(AVG(rides_completed), 2) AS avg_daily_rides

    FROM daily_driver_metrics
    GROUP BY driver_id
)

SELECT
    d.driver_id,
    d.full_name,
    d.city,
    v.vehicle_type,

    -- Performance
    COALESCE(es.total_earnings, 0) AS total_earnings,
    COALESCE(es.avg_daily_income, 0) AS avg_daily_income,

    COALESCE(ts.total_trips, 0) AS total_trips,
    COALESCE(ts.completed_trips, 0) AS completed_trips,
    COALESCE(ts.cancelled_trips, 0) AS cancelled_trips,
    COALESCE(ts.cancellation_rate, 0) AS cancellation_rate,

    -- Customer
    COALESCE(rs.avg_rating, 0) AS avg_rating,
    COALESCE(rs.total_ratings, 0) AS total_ratings,
    COALESCE(cs.total_complaints, 0) AS total_complaints,

    -- Workload
    COALESCE(ds.avg_online_hours, 0) AS avg_online_hours,
    COALESCE(ds.avg_idle_hours, 0) AS avg_idle_hours,
    COALESCE(ds.avg_daily_rides, 0) AS avg_daily_rides,

    -- Trip Performance
    COALESCE(ts.avg_trip_distance_km, 0) AS avg_trip_distance_km,
    COALESCE(ts.avg_trip_duration_min, 0) AS avg_trip_duration_min

FROM drivers d

LEFT JOIN vehicles v
    ON d.vehicle_id = v.vehicle_id

LEFT JOIN trip_summary ts
    ON d.driver_id = ts.driver_id

LEFT JOIN earnings_summary es
    ON d.driver_id = es.driver_id

LEFT JOIN rating_summary rs
    ON d.driver_id = rs.driver_id

LEFT JOIN complaint_summary cs
    ON d.driver_id = cs.driver_id

LEFT JOIN daily_summary ds
    ON d.driver_id = ds.driver_id;










CREATE OR REPLACE VIEW vw_driver_performance AS

SELECT
    driver_id,
    full_name,
    city,
    vehicle_type,

    total_earnings,
    avg_daily_income,

    total_trips,
    completed_trips,
    cancelled_trips,
    cancellation_rate,

    avg_rating,
    total_complaints,

    avg_online_hours,
    avg_idle_hours,
    avg_daily_rides,

    avg_trip_distance_km,
    avg_trip_duration_min

FROM vw_driver_master;







CREATE OR REPLACE VIEW vw_driver_burnout AS

SELECT
    driver_id,
    full_name,
    city,
    vehicle_type,

    avg_online_hours,
    avg_idle_hours,

    avg_rating,
    total_complaints,

    total_earnings,
    completed_trips,
    avg_daily_rides,

    ROUND(
        (avg_online_hours * 3)
        +
        (total_complaints * 0.5)
        -
        (avg_rating * 2),
        2
    ) AS burnout_score

FROM vw_driver_master;











CREATE OR REPLACE VIEW vw_burnout_city AS

SELECT
    city,

    COUNT(driver_id) AS total_drivers,

    ROUND(AVG(avg_online_hours), 2) AS avg_online_hours,

    ROUND(AVG(avg_rating), 2) AS avg_rating,

    SUM(total_complaints) AS total_complaints,

    ROUND(AVG(burnout_score), 2) AS avg_burnout_score,

    ROUND(MAX(burnout_score), 2) AS max_burnout_score

FROM vw_driver_burnout

GROUP BY city

ORDER BY avg_burnout_score DESC;



CREATE OR REPLACE VIEW vw_burnout_vehicle AS

SELECT
    vehicle_type,

    COUNT(driver_id) AS total_drivers,

    ROUND(AVG(avg_online_hours), 2) AS avg_online_hours,

    ROUND(AVG(avg_rating), 2) AS avg_rating,

    SUM(total_complaints) AS total_complaints,

    ROUND(AVG(burnout_score), 2) AS avg_burnout_score,

    ROUND(MAX(burnout_score), 2) AS max_burnout_score

FROM vw_driver_burnout

GROUP BY vehicle_type

ORDER BY avg_burnout_score DESC;








CREATE OR REPLACE VIEW vw_driver_risk AS

SELECT
    driver_id,
    full_name,
    city,
    vehicle_type,

    avg_online_hours,
    avg_rating,
    total_complaints,

    burnout_score,

    total_earnings,
    completed_trips,

    CASE
        WHEN avg_online_hours > 10
             AND avg_rating < 4.2
             AND total_complaints >= 5
        THEN 'High Risk'

        WHEN avg_online_hours > 10
             OR avg_rating < 4.2
             OR total_complaints >= 5
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS risk_status

FROM vw_driver_burnout;



select * from vw_driver_risk


CREATE OR REPLACE VIEW vw_dashboard_kpi AS

SELECT

    COUNT(driver_id) AS total_drivers,

    COALESCE(SUM(total_earnings), 0) AS total_earnings,

    COALESCE(SUM(total_trips), 0) AS total_trips,

    COALESCE(SUM(completed_trips), 0) AS completed_trips,

    ROUND(AVG(avg_rating), 2) AS avg_rating,

    ROUND(AVG(avg_online_hours), 2) AS avg_online_hours,

    ROUND(AVG(avg_idle_hours), 2) AS avg_idle_hours,

    ROUND(AVG(burnout_score), 2) AS avg_burnout_score,

    COUNT(*) FILTER (
        WHERE avg_online_hours > 10
        AND avg_rating < 4.2
        AND total_complaints >= 5
    ) AS high_risk_drivers

FROM vw_driver_burnout;


