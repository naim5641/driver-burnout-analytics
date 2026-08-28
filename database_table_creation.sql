
CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    gender VARCHAR(10),
    age INT,
    city VARCHAR(50),
    join_date DATE,
    vehicle_id INT,
    experience_years NUMERIC(4,2),
    driver_status VARCHAR(20)
);


CREATE TABLE trips (
    trip_id BIGSERIAL PRIMARY KEY,
    driver_id INT,
    trip_date DATE,
    pickup_time TIMESTAMP,
    drop_time TIMESTAMP,
    trip_distance_km NUMERIC(6,2),
    trip_duration_min INT,
    fare NUMERIC(8,2),
    surge_multiplier NUMERIC(3,2),
    completed BOOLEAN,
    cancelled BOOLEAN
);


CREATE TABLE daily_driver_metrics (
    metric_id BIGSERIAL PRIMARY KEY,
    driver_id INT,
    activity_date DATE,
    rides_completed INT,
    online_hours NUMERIC(4,2),
    login_count INT,
    idle_hours NUMERIC(4,2)
);

CREATE TABLE earnings (
    earning_id BIGSERIAL PRIMARY KEY,
    driver_id INT,
    earning_date DATE,
    trip_income NUMERIC(10,2),
    incentive NUMERIC(10,2),
    tips NUMERIC(10,2),
    total_income NUMERIC(10,2)
);


CREATE TABLE ratings (
    rating_id BIGSERIAL PRIMARY KEY,
    driver_id INT,
    rating_date DATE,
    customer_rating NUMERIC(2,1)
);


CREATE TABLE complaints (
    complaint_id BIGSERIAL PRIMARY KEY,
    driver_id INT,
    complaint_date DATE,
    complaint_type VARCHAR(100),
    resolved BOOLEAN
);


CREATE TABLE churn_labels (
    driver_id INT PRIMARY KEY,
    churned BOOLEAN,
    churn_date DATE
);


CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    vehicle_type VARCHAR(20),
    vehicle_model VARCHAR(50),
    manufacture_year INT
);





