CREATE TABLE IF NOT EXISTS monthly_driver_performance (
    performance_id BIGSERIAL PRIMARY KEY,
    driver_id INT,
    performance_month DATE,
    completed_trips INT,
    total_income NUMERIC(12,2),
    avg_rating NUMERIC(4,2),
    total_complaints INT,
    avg_online_hours NUMERIC(6,2),
    avg_idle_hours NUMERIC(6,2),
    cancellation_rate NUMERIC(6,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(driver_id, performance_month)
);



create or replace procedure refresh_monthly_driver_performance(
	p_month date
)
language plpgsql
as $$ 
begin

/*
    Remove existing summary for the selected month.
    This makes the procedure safely re-runnable.
*/

delete from monthly_driver_performance
where performance_month = date_trunc('month',p_month)::date;

/*
    Generate monthly performance summary
*/

insert into monthly_driver_performance (

        driver_id,
        performance_month,
        completed_trips,
        total_income,
        avg_rating,
        total_complaints,
        avg_online_hours,
        avg_idle_hours,
        cancellation_rate

    )

select 
d.driver_id,
date_trunc('month',p_month):: date as performance_month,
count(t.trip_id) filter(where t.completed = true) as completed_trips,
coalesce(sum(e.total_income),0) as total_income,
round(avg(r.customer_rating),2) as avg_rating,
count(c.complaint_id) as total_complaints,
round(avg(dm.online_hours),2) as avg_online_hours,
round(avg(dm.idel_hours),2) as avg_idle_hours,
round(

count(t.trip_id) filter(where t.cancelled = true)
*100.0
/
nullif(count(t.trip_id),0),2
) as cancellation_rate




from drivers as d

left join trips as t
	on d.driver_id = t.driver_id
	and t.trip_date >= date_trunc('month', p_month)
	and t.trip_date < date_trunc('month', p_month)+interval 'month'

left join earnings as e
	on d.driver_id = e.driver_id
	and e.earning_date >= date_trunc('month', p_month)
	and e.earning_date < date_trunc('month', p_month) + interval '1 month'




left join complaints as c
	on d.driver_id = c.driver_id
	and c.complaint_date >= date_trunc('month', p_month)
	and c.complaint_date < date_trunc('month', p_month) + interval '1 month'



left join daily_driver_metrics as dm
	on d.driver_id = dm.driver_id
	and dm.activity_date >= date_trunc('month', p_month)
	and dm.activity_date < date_trunc('month', p_month) + interval '1 month'

group by 
	driver_id;

end;
$$;

CALL refresh_monthly_driver_performance('2025-01-01');

