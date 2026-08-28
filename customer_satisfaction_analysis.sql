/*
	----- Customer Satisfaction (31–38) ------
	Average rating by city।
	Average rating by vehicle type।
	Complaint count by complaint type।
	Complaint rate by city।
	Complaint rate by vehicle type।
	Complaint resolution percentage।
	Rating distribution (1–5)।
	Drivers with high ratings but low earnings।

*/


/*
1.
Business Question:
Which cities have the highest average customer ratings?

Business Insight:
Cities with lower ratings may require additional driver training,
better service quality monitoring, or operational improvements.

*/


SELECT
    d.city,
    ROUND(AVG(r.customer_rating),2) AS average_rating
FROM drivers d
JOIN ratings r
ON d.driver_id = r.driver_id
GROUP BY d.city
ORDER BY average_rating DESC;



/*
2.
Business Question:
Does vehicle type influence customer satisfaction?

Business Insight:
Vehicle categories with lower ratings may indicate
comfort or service quality issues.
*/


SELECT
    v.vehicle_type,
    ROUND(AVG(r.customer_rating),2) AS average_rating
FROM ratings r
JOIN drivers d
ON r.driver_id = d.driver_id
JOIN vehicles v
ON d.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_type
ORDER BY average_rating DESC;


/*
3.
Business Question:
Which complaint types occur most frequently?

Business Insight:
Understanding common complaints helps prioritize
service improvements and driver training.
*/

SELECT
    complaint_type,
    COUNT(*) AS total_complaints
FROM complaints
GROUP BY complaint_type
ORDER BY total_complaints DESC;



/*
4. Complaint rate by city.
*/

with cte as (
select
	d.city,
	count(c.complaint_id) as total_complaint
from drivers as d
join complaints as c
on d.driver_id = c.driver_id
group by d.city
)

select 
*,
round(total_complaint / sum(total_complaint),2) as complaint_rate
from 
cte
group by cte.city



/*
4.
Business Question:
Which cities experience the highest complaint rates?

Business Insight:
Cities with high complaint rates should be investigated
for operational issues or driver performance problems.
*/



SELECT
    d.city,
    COUNT(c.complaint_id) AS complaints,
    COUNT(DISTINCT t.trip_id) AS completed_trips,
    ROUND(
        COUNT(c.complaint_id) * 100.0 /
        COUNT(DISTINCT t.trip_id),
        2
    ) AS complaint_rate
FROM drivers d
JOIN trips t
ON d.driver_id = t.driver_id
LEFT JOIN complaints c
ON d.driver_id = c.driver_id
AND t.trip_date = c.complaint_date
WHERE t.completed = TRUE
GROUP BY d.city
ORDER BY complaint_rate DESC;


/*
5.
Business Question:
Which vehicle types receive more complaints?

Business Insight:
Vehicle types with higher complaint rates may need
maintenance, upgrades, or targeted driver training.
*/

SELECT
    v.vehicle_type,
    COUNT(c.complaint_id) AS complaints,
    COUNT(DISTINCT t.trip_id) AS completed_trips,
    ROUND(
        COUNT(c.complaint_id) * 100.0 /
        COUNT(DISTINCT t.trip_id),
        2
    ) AS complaint_rate
FROM drivers d
JOIN trips t
ON d.driver_id = t.driver_id
LEFT JOIN complaints c
ON d.driver_id = c.driver_id
AND t.trip_date = c.complaint_date
JOIN vehicles as v
ON v.vehicle_id = d.vehicle_id
WHERE t.completed = TRUE
GROUP BY v.vehicle_type
ORDER BY complaint_rate DESC;


/*
6.
Business Question:
What percentage of customer complaints were resolved?

Business Insight:
A high resolution rate reflects strong customer support
and effective issue management.
*/


SELECT 
ROUND(SUM(CASE WHEN resolved = true THEN 1 ELSE 0 END)*100.0/COUNT(*),2) as resolution_percentage
FROM complaints



select * from ratings


/*
7.
Business Question:
How are customer ratings distributed?

Business Insight:
A healthy platform should have the majority
of ratings between 4 and 5 stars.
*/

SELECT
    customer_rating,
    COUNT(*) AS total_ratings,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ratings),2) AS percentage
FROM ratings
GROUP BY customer_rating
ORDER BY customer_rating DESC;



/*
8.
Business Question:
Which drivers maintain excellent customer ratings
despite earning relatively low income?

Business Insight:
These drivers provide excellent service but may not
be receiving enough ride opportunities.
They are ideal candidates for promotional campaigns,
priority ride allocation, or incentive programs.
*/


SELECT
	d.driver_id,
	d.full_name,
	d.city,
	ROUND(AVG(r.customer_rating),2) as average_rating,
	ROUND(AVG(e.total_income),2) as average_daily_income
FROM drivers as d
JOIN ratings as r
ON d.driver_id = r.driver_id
JOIN earnings as e
ON e.driver_id = d.driver_id
GROUP BY 
	d.driver_id,
	d.full_name,
	d.city
HAVING 
	AVG(r.customer_rating) >= 4.8
	AND
	AVG(e.total_income) < 
	(SELECT AVG(total_income) FROM earnings)
ORDER BY 4 DESC, 5 ASC




