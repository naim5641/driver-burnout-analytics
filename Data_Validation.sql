
-- Step 1. Data validation

SELECT COUNT(*) FROM vehicles;

SELECT COUNT(*) FROM drivers;

SELECT COUNT(*) FROM trips;

SELECT COUNT(*) FROM daily_driver_metrics;

SELECT COUNT(*) FROM earnings;

SELECT COUNT(*) FROM ratings;

SELECT COUNT(*) FROM complaints;

SELECT COUNT(*) FROM churn_labels;



-- duplicate check



SELECT
driver_id,
COUNT(*)
FROM drivers
GROUP BY driver_id
HAVING COUNT(*)>1;



SELECT trip_id, COUNT(*)
FROM trips
GROUP BY trip_id
HAVING COUNT(*) > 1


SELECT complaint_id, COUNT(*)
FROM complaints
GROUP BY complaint_id
HAVING COUNT(*) > 1


SELECT vehicle_id, COUNT(*)
FROM vehicles
GROUP BY vehicle_id
HAVING COUNT(*) > 1



-- null value check

SELECT *
FROM drivers
WHERE full_name IS NULL
OR gender IS NULL
OR city IS NULL;


SELECT *
FROM trips
WHERE driver_id IS NULL
OR fare IS NULL;

-- foreign key validation

SELECT t.driver_id
FROM trips t
LEFT JOIN drivers d
ON t.driver_id = d.driver_id
WHERE d.driver_id IS NULL;



SELECT r.driver_id
FROM ratings r
LEFT JOIN drivers d
ON r.driver_id=d.driver_id
WHERE d.driver_id IS NULL;


SELECT c.driver_id
FROM complaints c
LEFT JOIN drivers d
ON c.driver_id=d.driver_id
WHERE d.driver_id IS NULL;


-- vehicle validation

SELECT *
FROM drivers
WHERE vehicle_id NOT IN
(
SELECT vehicle_id
FROM vehicles
);

-- gender validation

SELECT DISTINCT gender
FROM drivers;


-- status validation

SELECT DISTINCT driver_status
FROM drivers;

-- age validation

SELECT *
FROM drivers
WHERE age<18
OR age>70;


-- experience Validation

SELECT *
FROM drivers
WHERE experience_years<0;


-- join date validation

SELECT *
FROM drivers
WHERE join_date>CURRENT_DATE;


-- trip distance validation

SELECT *
FROM trips
WHERE trip_distance_km<=0;


-- pickup or drop

SELECT *
FROM trips
WHERE pickup_time>=drop_time;

-- trip cancelled validation


SELECT *
FROM trips
WHERE completed=TRUE
AND cancelled=TRUE;


-- online hours

SELECT *
FROM daily_driver_metrics
WHERE online_hours<0
OR online_hours>24;

-- login count

SELECT *
FROM daily_driver_metrics
WHERE login_count<0;

-- idle hours

SELECT *
FROM daily_driver_metrics
WHERE idle_hours<0;


--- earnings validation

SELECT *
FROM earnings
WHERE total_income<>
trip_income+tips+incentive;


-- rating validation

SELECT *
FROM ratings
WHERE customer_rating<1
OR customer_rating>5;


-- remove extra space


UPDATE drivers
SET full_name = TRIM(full_name),
city = TRIM(city),
driver_status = TRIM(driver_status);


-- standardize gender

UPDATE drivers
SET gender =
CASE
WHEN LOWER(gender)='male' THEN 'Male'
WHEN LOWER(gender)='female' THEN 'Female'
ELSE gender

END;



-- incorrect total income


UPDATE earnings
SET total_income =
ROUND(trip_income + incentive + tips,2)
WHERE
ROUND(total_income,2) <>
ROUND(trip_income + incentive + tips,2);



-- remove duplicate complaints.


SELECT
driver_id,
complaint_date,
complaint_type,
COUNT(*)
FROM complaints
GROUP BY
driver_id,
complaint_date,
complaint_type
HAVING COUNT(*) > 1;


-- standardize complaint type


UPDATE complaints
SET complaint_type = INITCAP(TRIM(complaint_type));


-- remove duplicate ratings


SELECT
driver_id,
rating_date,
customer_rating,
COUNT(*)
FROM ratings
GROUP BY
driver_id,
rating_date,
customer_rating
HAVING COUNT(*) > 1;





