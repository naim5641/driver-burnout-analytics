/*
	--- Time-Series Analysis ---
	Running total revenue over time.
	7-day moving average revenue.
	Month-over-month revenue growth using LAG().
	Rank drivers by monthly earnings using RANK() or DENSE_RANK().
	Divide drivers into performance quartiles using NTILE(4).

*/


/*
1.
Business Question:
How does cumulative revenue grow over time?

Business Insight:
Running total helps monitor overall business growth and
identify periods of rapid or slow revenue accumulation.
*/



select 
	earning_date,
	sum(total_income) as daily_revenue,
	sum(sum(total_income)) over(order by earning_date) as daily_revenue_trend
from earnings
group by earning_date



/*
2.
Business Question:
What is the 7-day moving average of revenue?

Business Insight:
A moving average smooths daily fluctuations and
reveals the underlying revenue trend.
*/


with daily_revenue as 
(
	select
		earning_date,
		sum(total_income) as daily_revenue
	from earnings
	group by earning_date
)
select
	earning_date,
	daily_revenue,
	round(avg(daily_revenue) over(order by earning_date rows between 6 preceding and current row),2) as moving_avg
from daily_revenue


-- Month-over-month revenue growth using LAG().
/*
3.
Business Question:
How has monthly revenue changed compared to the previous month?

Business Insight:
Positive growth indicates business expansion,
while negative growth may signal seasonal decline
or operational issues.
*/

select 
	date_trunc('month',earning_date) as month,
	sum(total_income) as monthly_revenue,
	lag(sum(total_income)) over(order by date_trunc('month',earning_date)) as previous_month_revenue,
	round((sum(total_income) - lag(sum(total_income)) over(order by date_trunc('month',earning_date)))*100.0 /
	lag(sum(total_income)) over(order by date_trunc('month',earning_date)),2) as revenue_growth_percent 
from earnings
group by date_trunc('month',earning_date)


-- another approach

with monthly_revenue as (

	select
		date_trunc('month', earning_date) as month,
		sum(total_income) as revenue
	from earnings
	group by date_trunc('month', earning_date)
)
select 
month,
revenue,
lag(revenue) over(order by month) as previous_revenue,
round((revenue-lag(revenue) over(order by month))*100/lag(revenue) over(order by month),2)
from monthly_revenue
order by month




--Rank drivers by monthly earnings using RANK() or DENSE_RANK().

/*
4.
Business Question:
Who are the top earning drivers each month?

Business Insight:
Monthly ranking helps identify consistent top performers
for incentive and reward programs.
*/
with monthly_revenue as (
select 
	d.driver_id as driver_id,
	d.full_name as full_name,
	date_trunc('month', e.earning_date) as month,
	sum(e.total_income) as revenue
from
drivers as d
join earnings as e
on d.driver_id = e.driver_id
group by d.driver_id, d.full_name,month
)
select
	*,
	dense_rank() over (partition by month order by revenue desc) as rnk
from monthly_revenue



-- Divide drivers into performance quartiles using NTILE(4).
/*
5.
Business Question:
How can drivers be segmented based on total earnings?

Business Insight:
Quartile segmentation helps identify
Top Performers,
Average Performers,
Low Performers,
and Drivers Needing Support.
*/
with driver_income as (
select 
	driver_id,
	sum(total_income) as total_income
from earnings
group by driver_id
)

select
	driver_id,
	total_income,
	ntile(4) over ( order by total_income desc) as performace_quertile
from driver_income
order by total_income desc








