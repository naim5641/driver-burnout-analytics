/*
=========================================================
Driver Burnout & Retention Analytics
File: 18_Triggers.sql
Database: PostgreSQL

Triggers:

1. Automatically calculate total income
2. Automatically validate trip data
3. Automatically validate rating data

=========================================================
*/


/*
=========================================================
1. AUTO CALCULATE TOTAL INCOME
=========================================================

Business Rule:

total_income =
trip_income + incentive + tips

earnings record insert/update
total_income automatically calculate
=========================================================
*/



create or replace function calculate_total_income()
returns trigger
language plpgsql
as $$
begin
	new.total_income :=
		coalesce(new.trip_income, 0)
		+
		coalesce(new.incentive, 0)
		+
		coalesce(new.tips, 0);
	return new;
end;
$$;



drop trigger if exists calculate_total_income
on earnings;

create trigger calculate_total_income
before insert or update
on earnings
for each row
execute function calculate_total_income();




SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'earnings';



INSERT INTO earnings (
    driver_id,
    earning_date,
    trip_income,
    incentive,
    tips,
    total_income
)
VALUES (
    3,
    CURRENT_DATE,
    500,
    100,
    50,
    0
);



UPDATE earnings
SET 
    trip_income = 700,
    incentive = 150,
    tips = 50
WHERE earning_id = 10;



SELECT 
    earning_id,
    trip_income,
    incentive,
    tips,
    total_income
FROM earnings
WHERE earning_id = 10;


UPDATE earnings
SET
    trip_income = 500,
    incentive = NULL,
    tips = NULL
WHERE earning_id = 10;




SELECT 
    trip_income,
    incentive,
    tips,
    total_income
FROM earnings
WHERE earning_id = 10;



/*
=========================================================
2. VALIDATE TRIP DATA
=========================================================
*/


create or replace function validate_trip_data()
returns trigger
language plpgsql
as $$
begin


-- distance validation

if new.trip_distance_km is not null
and new.trip_distance_km < 0
then raise exception 'Trip distance cannot be negative';
end if;


-- Duration validation

if new.trip_duration_min is not null
and new.trip_duration_min <= 0
then raise exception 'Trip duration must be greater than zero';
end if;


-- fare validation

if new.fare is not null
and new.fare < 0
then raise exception 'Fare cannot be negative';
end if;

-- surge validation

if new.surge_multiplier is not null
and new.surge_multiplier < 1
then raise exception 'Surge multiplier cannot be less then 1';
end if;

-- time validation

if new.pickup_time is not null
and new.drop_time is not null
and new.drop_time < new.pickup_time
then raise exception 'Drop time cannot be earlier than pickup time';
end if;

return new;

end;
$$;


drop trigger if exists validate_trip_data
on trips;

create trigger validate_trip_data
before insert or update
on trips
for each row
execute function validate_trip_data();



UPDATE trips
SET 
    trip_distance_km = 12.5,
    trip_duration_min = 35,
    fare = 450,
    surge_multiplier = 1.5
WHERE trip_id = 1;

select *from trips 
where trip_id = 1



UPDATE trips
SET trip_distance_km = -10
WHERE trip_id = 1;


UPDATE trips
SET trip_duration_min = 0
WHERE trip_id = 1;


UPDATE trips
SET fare = -500
WHERE trip_id = 1;



UPDATE trips
SET 
    pickup_time = '2026-08-10 12:00:00',
    drop_time = '2026-08-10 11:30:00'
WHERE trip_id = 1;



/*
=========================================================
3. VALIDATE CUSTOMER RATING
=========================================================
*/



create or replace function validate_customer_rating()
returns trigger
language plpgsql
as $$
begin

if new.customer_rating is null
then raise exception 'Customer rating cannot be null';
end if;

if new.customer_rating < 1.0
or new.customer_rating > 5.0
then raise exception 'Customer rating must be between 1.0 and 5.0';
end if;
return new;


end;
$$;



drop trigger if exists validate_customer_rating
on ratings;

create trigger validate_customer_rating
before insert or update
on ratings
for each row
execute function validate_customer_rating();









