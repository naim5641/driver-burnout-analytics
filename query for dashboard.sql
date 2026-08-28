/*
Total Drivers
Total Revenue
Completed Trips
Average Rating
Churn Rate
*/







SELECT
    COUNT(DISTINCT d.driver_id) AS total_drivers,

    COALESCE(
        (SELECT SUM(e.total_income)
         FROM earnings e),
        0
    ) AS total_revenue,

    COALESCE(
        (SELECT COUNT(*)
         FROM trips
         WHERE completed = TRUE),
        0
    ) AS completed_trips,

    ROUND(
        (
            SELECT AVG(r.customer_rating)
            FROM ratings r
        ),
        2
    ) AS average_rating,

    ROUND(
        (
            SELECT COUNT(*)
            FROM churn_labels
            WHERE churned = TRUE
        ) * 100.0
        /
        NULLIF(COUNT(DISTINCT d.driver_id), 0),
        2
    ) AS churn_rate

FROM drivers d;



select * from trips



--- Revenue Trend



SELECT
    DATE_TRUNC('month', earning_date)::DATE AS month,
    SUM(trip_income) AS trip_income,
    SUM(incentive) AS incentive,
    SUM(tips) AS tips,
    SUM(total_income) AS total_revenue,
    COUNT(DISTINCT driver_id) AS active_drivers

FROM earnings

GROUP BY
    DATE_TRUNC('month', earning_date)

ORDER BY
    month;






--- Driver Risk — High / Medium / Low





WITH activity AS (

    SELECT
        driver_id,
        AVG(online_hours) AS avg_online_hours,
        AVG(idle_hours) AS avg_idle_hours
    FROM daily_driver_metrics
    GROUP BY driver_id
),

complaints AS (

    SELECT
        driver_id,
        COUNT(*) AS total_complaints
    FROM complaints
    GROUP BY driver_id
),

ratings AS (

    SELECT
        driver_id,
        AVG(customer_rating) AS average_rating
    FROM ratings
    GROUP BY driver_id
),

income AS (

    SELECT
        driver_id,
        AVG(total_income) AS avg_daily_income
    FROM earnings
    GROUP BY driver_id

),

driver_risk AS (

    SELECT
        d.driver_id,

        (
            COALESCE(a.avg_online_hours, 0) * 3
            +
            COALESCE(a.avg_idle_hours, 0) * 2
            +
            COALESCE(c.total_complaints, 0) * 0.5
            -
            COALESCE(r.average_rating, 0) * 2
            -
            COALESCE(i.avg_daily_income, 0) / 100
        ) AS risk_score

    FROM drivers d

    LEFT JOIN activity a
        ON d.driver_id = a.driver_id

    LEFT JOIN complaints c
        ON d.driver_id = c.driver_id

    LEFT JOIN ratings r
        ON d.driver_id = r.driver_id

    LEFT JOIN income i
        ON d.driver_id = i.driver_id
)

SELECT

    CASE
        WHEN risk_score >= 35 THEN 'High Risk'
        WHEN risk_score >= 20 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level,

    COUNT(*) AS driver_count

FROM driver_risk

GROUP BY

    CASE
        WHEN risk_score >= 35 THEN 'High Risk'
        WHEN risk_score >= 20 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END

ORDER BY
    driver_count DESC;







-- Burnout by City


WITH activity AS (

    SELECT
        driver_id,
        AVG(online_hours) AS avg_online_hours,
        AVG(idle_hours) AS avg_idle_hours
    FROM daily_driver_metrics
    GROUP BY driver_id

),

complaints AS (

    SELECT
        driver_id,
        COUNT(*) AS total_complaints
    FROM complaints
    GROUP BY driver_id

),

ratings AS (

    SELECT
        driver_id,
        AVG(customer_rating) AS average_rating
    FROM ratings
    GROUP BY driver_id

),

income AS (

    SELECT
        driver_id,
        AVG(total_income) AS avg_daily_income
    FROM earnings
    GROUP BY driver_id

),

driver_burnout AS (

    SELECT

        d.driver_id,
        d.city,

        (
            COALESCE(a.avg_online_hours, 0) * 3
            +
            COALESCE(a.avg_idle_hours, 0) * 2
            +
            COALESCE(c.total_complaints, 0) * 0.5
            -
            COALESCE(r.average_rating, 0) * 2
            -
            COALESCE(i.avg_daily_income, 0) / 100
        ) AS burnout_score

    FROM drivers d

    LEFT JOIN activity a
        ON d.driver_id = a.driver_id

    LEFT JOIN complaints c
        ON d.driver_id = c.driver_id

    LEFT JOIN ratings r
        ON d.driver_id = r.driver_id

    LEFT JOIN income i
        ON d.driver_id = i.driver_id
)

SELECT

    city,

    ROUND(
        AVG(burnout_score),
        2
    ) AS avg_burnout_score

FROM driver_burnout

GROUP BY city

ORDER BY avg_burnout_score DESC;




-- Revenue by Vehicle Type




SELECT

    v.vehicle_type,

    SUM(e.trip_income) AS trip_income,

    SUM(e.incentive) AS incentive,

    SUM(e.tips) AS tips,

    SUM(e.total_income) AS total_revenue,

    COUNT(DISTINCT e.driver_id) AS active_drivers

FROM earnings e

JOIN drivers d
    ON e.driver_id = d.driver_id

JOIN vehicles v
    ON d.vehicle_id = v.vehicle_id

GROUP BY

    v.vehicle_type

ORDER BY

    total_revenue DESC;





-- Monthly Active Drivers — Line Chart



SELECT

    DATE_TRUNC(
        'month',
        activity_date
    )::DATE AS month,

    COUNT(
        DISTINCT driver_id
    ) AS active_drivers,

    ROUND(
        AVG(online_hours),
        2
    ) AS avg_online_hours,

    ROUND(
        AVG(idle_hours),
        2
    ) AS avg_idle_hours

FROM daily_driver_metrics

GROUP BY

    DATE_TRUNC(
        'month',
        activity_date
    )

ORDER BY month;


--- Customer Satisfaction


WITH monthly_ratings AS (

    SELECT

        DATE_TRUNC(
            'month',
            rating_date
        )::DATE AS month,

        AVG(customer_rating) AS average_rating

    FROM ratings

    GROUP BY
        DATE_TRUNC('month', rating_date)

),

monthly_complaints AS (

    SELECT

        DATE_TRUNC(
            'month',
            complaint_date
        )::DATE AS month,

        COUNT(*) AS complaint_count

    FROM complaints

    GROUP BY
        DATE_TRUNC('month', complaint_date)

)

SELECT

    COALESCE(
        r.month,
        c.month
    ) AS month,

    ROUND(
        r.average_rating,
        2
    ) AS average_rating,

    COALESCE(
        c.complaint_count,
        0
    ) AS complaint_count

FROM monthly_ratings r

FULL OUTER JOIN monthly_complaints c

ON r.month = c.month

ORDER BY month;




-- Top 10 At-Risk Drivers

WITH activity AS (

    SELECT

        driver_id,

        AVG(online_hours) AS avg_online_hours,

        AVG(idle_hours) AS avg_idle_hours

    FROM daily_driver_metrics

    GROUP BY driver_id

),

complaints AS (

    SELECT

        driver_id,

        COUNT(*) AS total_complaints

    FROM complaints

    GROUP BY driver_id

),

ratings AS (

    SELECT

        driver_id,

        AVG(customer_rating) AS average_rating

    FROM ratings

    GROUP BY driver_id

),

income AS (

    SELECT

        driver_id,

        AVG(total_income) AS avg_daily_income

    FROM earnings

    GROUP BY driver_id

),

risk AS (

    SELECT

        d.driver_id,

        d.full_name,

        d.city,

        v.vehicle_type,

        d.driver_status,

        d.experience_years,

        a.avg_online_hours,

        a.avg_idle_hours,

        COALESCE(c.total_complaints, 0)
            AS total_complaints,

        r.average_rating,

        i.avg_daily_income,

        (

            COALESCE(a.avg_online_hours, 0) * 3

            +

            COALESCE(a.avg_idle_hours, 0) * 2

            +

            COALESCE(c.total_complaints, 0) * 0.5

            -

            COALESCE(r.average_rating, 0) * 2

            -

            COALESCE(i.avg_daily_income, 0) / 100

        ) AS burnout_score

    FROM drivers d

    LEFT JOIN activity a
        ON d.driver_id = a.driver_id

    LEFT JOIN complaints c
        ON d.driver_id = c.driver_id

    LEFT JOIN ratings r
        ON d.driver_id = r.driver_id

    LEFT JOIN income i
        ON d.driver_id = i.driver_id

    LEFT JOIN vehicles v
        ON d.vehicle_id = v.vehicle_id
)

SELECT

    driver_id,

    full_name,

    city,

    vehicle_type,

    driver_status,

    experience_years,

    ROUND(
        burnout_score,
        2
    ) AS burnout_score,

    ROUND(
        average_rating,
        2
    ) AS average_rating,

    total_complaints,

    ROUND(
        avg_daily_income,
        2
    ) AS avg_daily_income,

    ROUND(
        avg_online_hours,
        2
    ) AS avg_online_hours,

    CASE

        WHEN burnout_score >= 35
            THEN 'High Risk'

        WHEN burnout_score >= 20
            THEN 'Medium Risk'

        ELSE 'Low Risk'

    END AS risk_level

FROM risk

WHERE burnout_score >= 35

ORDER BY

    burnout_score DESC

LIMIT 10;



--- Driver Performance Table 


WITH trips_summary AS (

    SELECT

        driver_id,

        COUNT(*) AS total_trips,

        COUNT(*) FILTER (
            WHERE completed = TRUE
        ) AS completed_trips,

        COUNT(*) FILTER (
            WHERE cancelled = TRUE
        ) AS cancelled_trips

    FROM trips

    GROUP BY driver_id

),

earnings_summary AS (

    SELECT

        driver_id,

        SUM(total_income) AS total_income

    FROM earnings

    GROUP BY driver_id

),

rating_summary AS (

    SELECT

        driver_id,

        AVG(customer_rating) AS average_rating

    FROM ratings

    GROUP BY driver_id

)

SELECT

    d.driver_id,

    d.full_name,

    d.city,

    COALESCE(t.total_trips, 0)
        AS total_trips,

    COALESCE(t.completed_trips, 0)
        AS completed_trips,

    COALESCE(t.cancelled_trips, 0)
        AS cancelled_trips,

    ROUND(
        COALESCE(e.total_income, 0),
        2
    ) AS total_income,

    ROUND(
        r.average_rating,
        2
    ) AS average_rating,

    ROUND(

        COALESCE(t.cancelled_trips, 0)
        * 100.0
        /
        NULLIF(t.total_trips, 0),

        2

    ) AS cancellation_rate

FROM drivers d

LEFT JOIN trips_summary t
    ON d.driver_id = t.driver_id

LEFT JOIN earnings_summary e
    ON d.driver_id = e.driver_id

LEFT JOIN rating_summary r
    ON d.driver_id = r.driver_id

ORDER BY

    total_income DESC;





--- for small kpi




SELECT

    COUNT(*) AS total_complaints,

    COUNT(*) FILTER (
        WHERE resolved = TRUE
    ) AS resolved_complaints,

    ROUND(

        COUNT(*) FILTER (
            WHERE resolved = TRUE
        ) * 100.0
        /
        NULLIF(COUNT(*), 0),

        2

    ) AS resolution_percentage

FROM complaints;





--- high rating + low earnings


WITH income AS (

    SELECT

        driver_id,

        SUM(total_income) AS total_income

    FROM earnings

    GROUP BY driver_id

),

ratings AS (

    SELECT

        driver_id,

        AVG(customer_rating) AS average_rating

    FROM ratings

    GROUP BY driver_id

)

SELECT

    d.driver_id,

    d.full_name,

    d.city,

    ROUND(r.average_rating, 2)
        AS average_rating,

    ROUND(i.total_income, 2)
        AS total_income

FROM drivers d

JOIN ratings r
    ON d.driver_id = r.driver_id

JOIN income i
    ON d.driver_id = i.driver_id

WHERE r.average_rating >= 4.5

AND i.total_income < (

    SELECT AVG(total_income)

    FROM income

)

ORDER BY

    r.average_rating DESC;


-- for slicer


SELECT

    d.driver_id,

    d.city,

    d.driver_status,

    d.gender,

    d.age,

    d.join_date,

    d.experience_years,

    v.vehicle_id,

    v.vehicle_type,

    v.vehicle_model,

    v.manufacture_year

FROM drivers d

LEFT JOIN vehicles v

ON d.vehicle_id = v.vehicle_id;





-- experiecne slicer


SELECT

    driver_id,

    CASE

        WHEN experience_years < 2
            THEN '0–2 Years'

        WHEN experience_years < 5
            THEN '2–5 Years'

        WHEN experience_years < 10
            THEN '5–10 Years'

        ELSE '10+ Years'

    END AS experience_level

FROM drivers;










