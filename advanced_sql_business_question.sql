/*

	--- Window Functions ---
	Rank drivers within each city.
	Top 3 earners from each city.
	Running total of trips.
	Running total of earnings.
	Moving average of ratings.
	Previous month's revenue using LAG().
	Next month's revenue using LEAD().
	Highest earning day using FIRST_VALUE().
	Lowest earning day using LAST_VALUE().
	Revenue percentile using PERCENT_RANK().

*/






/*
	
*/
/*
	1. Rank drivers within each city.
	Business Question:
	Who are the top-performing drivers within each city?
	
	Business Insight:
	This ranking helps identify the best drivers in every city
	for rewards, recognition, and incentive programs.
*/


select 
	d.driver_id,
	d.full_name,
	d.city,
	sum(e.total_income) as total_income,
	dense_rank() over(partition by d.city order by sum(e.total_income) desc)
from drivers as d
join earnings as e
on d.driver_id = e.driver_id
group by 
	d.driver_id,
	d.full_name,
	d.city



/*

2. Top 3 earners from each city.
Business Question:
Who are the top 3 earning drivers in each city?

Business Insight:
Useful for city-level incentive programs and recognizing
high-performing drivers.

*/


with driver_rnk as (
select 
	d.driver_id,
	d.full_name,
	d.city,
	sum(e.total_income) as total_income,
	dense_rank() over(partition by d.city order by sum(e.total_income) desc) as rnk
from drivers as d
join earnings as e
on d.driver_id = e.driver_id
group by 
	d.driver_id,
	d.full_name,
	d.city
) 

select 
	*
from driver_rnk
where rnk <= 3




/*


--- Running total of trips ---

	Business Question:
	How does the cumulative number of completed trips grow over time?
	
	Business Insight:
	Running totals reveal long-term platform growth.


*/





with daily_trips as (
select
	trip_date,
	count(*) as total_trips
from trips
where completed = true
group by trip_date

)
select
*,
sum(total_trips) over (order by trip_date) as running_total
from daily_trips



/*
	
	Business Question:
	How does cumulative revenue increase over time?
	
	Business Insight:
	Tracks business growth and cumulative revenue.
*/


with daily_earning as 
(
	select
		earning_date,
		sum(total_income) as total_income
	from earnings
	group by earning_date
)
select
*,
sum(total_income) over(order by earning_date) as running_income
from daily_earning


/*
5. Moving average of ratings.
Business Question:
How has average customer rating changed over time?

Business Insight:
Smooths daily fluctuations to monitor service quality trends.
*/


with daily_ratings as(
select
	rating_date,
	round(avg(customer_rating),2) as avg_rating
from ratings
group by rating_date
)

select
	*,
	round(avg(avg_rating) over(order by rating_date rows between 6 preceding and current row),2) running_rating
from daily_ratings


/*
6.
Business Question:
What was the previous month's revenue?

Business Insight:
Enables month-over-month performance comparison.
*/
with monthly_revenue as (
select 
	date_trunc('month', earning_date) as month,
	sum(total_income) as total_revenue
from earnings
group by date_trunc('month', earning_date)
)

select 
	*,
	lag(total_revenue) over ( order by month ) as previous_month_revenue
from 
	monthly_revenue



/*
7. 
Business Question:
What is the next month's revenue?

Business Insight:
Useful for comparing current performance with the following month.
*/

with monthly_revenue as (
select 
	date_trunc('month', earning_date) as month,
	sum(total_income) as total_revenue
from earnings
group by date_trunc('month', earning_date)
)

select 
	*,
	lead(total_revenue) over ( order by month ) as next_month_revenue
from 
	monthly_revenue


/*
8.
Business Question:
Which day generated the highest revenue?

Business Insight:
Identifies peak business days for planning promotions
and staffing.
*/

with dailly_revenue as (
select
	earning_date,
	sum(total_income) as total_revenue
from earnings
group by
	earning_date

)

select
	*,
	first_value(earning_date) over (order by total_revenue desc) as first_highest_day,
	first_value(total_revenue) over(order by total_revenue desc) as first_highest_revenue
from dailly_revenue


/*
9.
Business Question:
Which day generated the lowest revenue?

Business Insight:
Helps identify weak-demand periods for targeted marketing.
*/


with dailly_revenue as (
select
	earning_date,
	sum(total_income) as total_revenue
from earnings
group by
	earning_date

)

select
	*,
	last_value(earning_date) over (order by total_revenue) as first_lowest_day,
	last_value(total_revenue) over(order by total_revenue) as first_lowest_revenue
from dailly_revenue




/*

10.
Business Question:
How does each driver's revenue compare with others?

Business Insight:
Identifies top-performing and low-performing drivers
using percentile ranking.

*/



with daily_revenue as (
select
	d.driver_id,
	sum(e.total_income) as total_revenue
from earnings as e
join drivers as d
on d.driver_id = e.driver_id
group by d.driver_id
)

select
*,
percent_rank() over(order by total_revenue) as revenue_percentile
from daily_revenue
order by total_revenue desc




