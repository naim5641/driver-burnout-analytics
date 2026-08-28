/*
=========================================================
Driver Burnout & Retention Analytics
File: 17_Functions.sql
Database: PostgreSQL

Purpose:
Reusable business logic using PostgreSQL Functions
=========================================================
*/


/*
=========================================================
1. Calculate Driver Burnout Score
=========================================================
*/



create or replace function calculate_burnout_score(
	p_online_hours NUMERIC,
    p_idle_hours NUMERIC,
    p_complaints INT,
    p_rating NUMERIC,
    p_avg_income NUMERIC
)

returns NUMERIC
language plpgsql
as $$ 
declare
	v_score NUMERIC;
begin

	v_score :=
	 (coalesce(p_online_hours,0)*3) 
	+(coalesce(p_idle_hours,0)*2)
	+(coalesce(p_complaints,0) * 0.5)
	-(coalesce(p_rating,0)*2)
	-(coalesce(p_avg_income,0)/100);
	return round(v_score,2);
end;
$$;



SELECT calculate_burnout_score(11,3,5,4.2,850)




/*
=========================================================
2. Get Driver Performance Grade
=========================================================
*/

create or replace function get_driver_grade(
	p_rating NUMERIC,
    p_completed_trips INT,
    p_cancellation_rate NUMERIC
)
returns varchar
language plpgsql
as $$
begin

	if p_rating >= 4.7 
	and p_completed_trips >= 1000
	and p_cancellation_rate < 5
	then return 'Excellent';

	elsif  p_rating >= 4.5
	and p_completed_trips >= 500
	and p_cancellation_rate < 10
	then return 'Very Good';

	elsif p_rating >= 4.0
	and p_completed_trips >= 200
	and p_cancellation_rate < 15
	then return 'Good';

	elsif p_rating >= 3.5
	then return 'Average';

	else return 'Needs Imporovement';

	end if;
end;
$$;

select get_driver_grade(
    4.8,
    1200,
    3
);


/*
=========================================================
3. Calculate Cancellation Rate
=========================================================
*/

create or replace function calculate_cancellation_rate(
 	p_cancelled_trips int,
    p_total_trips int

)
returns numeric
language plpgsql
immutable
as $$
begin

	if p_total_trips is null
	or p_total_trips = 0
	then return 0;
	end if;

	return round(
			(p_cancelled_trips * 100.0)
	        / p_total_trips,
	        2
	);

end;
$$;


/*
=========================================================
4. Calculate Revenue Growth %
=========================================================
*/


create or replace function calculate_growth_percentage(
	p_current_revenue NUMERIC,
    p_previous_revenue NUMERIC
)

returns numeric
language plpgsql
immutable
as $$
begin

if p_previous_revenue is null
or p_previous_revenue = 0
then return null;
end if;

return round(
		
 		((p_current_revenue - p_previous_revenue)* 100.0)
        / p_previous_revenue,
        2
);

end;
$$;












