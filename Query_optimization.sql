/*
=========================================================
Driver Burnout & Retention Analytics
File: 16_Query_Optimization.sql
Database: PostgreSQL

Purpose:
    Analyze and improve SQL query performance using:

    1. EXPLAIN
    2. EXPLAIN ANALYZE
    3. Index Scan
    4. Bitmap Index Scan
    5. Sequential Scan
    6. Composite Index
    7. Partial Index
    8. Query Refactoring
    9. Aggregation Optimization
   10. JOIN Optimization

IMPORTANT:
Run the queries BEFORE and AFTER creating indexes
to compare execution plans and execution time.
=========================================================
*/


/*
=========================================================
SECTION 1
Basic EXPLAIN ANALYZE
=========================================================
*/

EXPLAIN ANALYZE

SELECT *

FROM trips

WHERE driver_id = 100;


/*
Expected observation:

Before index:
    Seq Scan

After index:
    Index Scan

The exact execution plan depends on table size,
data distribution and PostgreSQL statistics.
*/


/*
=========================================================
SECTION 2
Date Filtering Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    trip_date,
    COUNT(*) AS total_trips

FROM trips

WHERE trip_date >= DATE '2025-01-01'

AND trip_date < DATE '2025-02-01'

GROUP BY trip_date

ORDER BY trip_date;


/*
Index used:

idx_trips_trip_date
*/


/*
=========================================================
SECTION 3
Driver + Date Composite Index
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,
    trip_date,
    COUNT(*) AS total_trips

FROM trips

WHERE driver_id = 100

AND trip_date >= DATE '2025-01-01'

AND trip_date < DATE '2025-02-01'

GROUP BY

driver_id,
trip_date;


/*
Recommended index:

idx_trips_driver_date
*/


/*
=========================================================
SECTION 4
Completed Trips Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    COUNT(*) AS completed_trips

FROM trips

WHERE completed = TRUE

GROUP BY driver_id;


/*
Recommended partial index:

idx_trips_completed_only
*/


/*
=========================================================
SECTION 5
Cancelled Trips Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    COUNT(*) AS cancelled_trips

FROM trips

WHERE cancelled = TRUE

GROUP BY driver_id;


/*
Recommended partial index:

idx_trips_cancelled_only
*/


/*
=========================================================
SECTION 6
Earnings by Driver
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    SUM(total_income) AS total_income

FROM earnings

GROUP BY driver_id;


/*
Recommended index:

idx_earnings_driver_id
*/


/*
=========================================================
SECTION 7
Daily Revenue Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    earning_date,

    SUM(total_income) AS daily_revenue

FROM earnings

GROUP BY earning_date

ORDER BY earning_date;


/*
Recommended index:

idx_earnings_date
*/


/*
=========================================================
SECTION 8
Driver + Date Earnings Query
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    earning_date,

    SUM(total_income) AS total_income

FROM earnings

WHERE driver_id = 100

AND earning_date >= DATE '2025-01-01'

AND earning_date < DATE '2025-02-01'

GROUP BY

driver_id,
earning_date;


/*
Recommended index:

idx_earnings_driver_date
*/


/*
=========================================================
SECTION 9
Rating Query Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    AVG(customer_rating) AS average_rating

FROM ratings

GROUP BY driver_id;


/*
Recommended index:

idx_ratings_driver_id
*/


/*
=========================================================
SECTION 10
Rating History Query
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    rating_date,

    customer_rating

FROM ratings

WHERE driver_id = 100

ORDER BY rating_date;


/*
Recommended index:

idx_ratings_driver_date
*/


/*
=========================================================
SECTION 11
Complaint Query Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    COUNT(*) AS complaint_count

FROM complaints

GROUP BY driver_id;


/*
Recommended index:

idx_complaints_driver_id
*/


/*
=========================================================
SECTION 12
Complaint + Date Query
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    COUNT(*) AS complaints

FROM complaints

WHERE complaint_date >= DATE '2025-01-01'

AND complaint_date < DATE '2025-02-01'

GROUP BY driver_id;


/*
Recommended index:

idx_complaints_driver_date
*/


/*
=========================================================
SECTION 13
Daily Driver Metrics Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    AVG(online_hours) AS avg_online_hours,

    AVG(idle_hours) AS avg_idle_hours

FROM daily_driver_metrics

GROUP BY driver_id;


/*
Recommended index:

idx_metrics_driver_id
*/


/*
=========================================================
SECTION 14
Driver Activity by Date
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    activity_date,

    online_hours,

    idle_hours

FROM daily_driver_metrics

WHERE driver_id = 100

AND activity_date >= DATE '2025-01-01'

AND activity_date < DATE '2025-02-01'

ORDER BY activity_date;


/*
Recommended index:

idx_metrics_driver_date
*/


/*
=========================================================
SECTION 15
JOIN Optimization
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    d.driver_id,

    d.full_name,

    SUM(e.total_income) AS total_income

FROM drivers d

JOIN earnings e

ON d.driver_id = e.driver_id

GROUP BY

    d.driver_id,
    d.full_name

ORDER BY total_income DESC;


/*
Important indexes:

drivers.driver_id
    → Primary Key index

earnings.driver_id
    → idx_earnings_driver_id
*/


/*
=========================================================
SECTION 16
JOIN + Date Filter
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    d.city,

    SUM(e.total_income) AS revenue

FROM drivers d

JOIN earnings e

ON d.driver_id = e.driver_id

WHERE e.earning_date >= DATE '2025-01-01'

AND e.earning_date < DATE '2025-02-01'

GROUP BY d.city;


/*
Important indexes:

idx_earnings_driver_date
idx_earnings_date
*/


/*
=========================================================
SECTION 17
Avoid SELECT *
=========================================================
*/

-- Less efficient when only a few columns are required

EXPLAIN ANALYZE

SELECT *

FROM drivers

WHERE city = 'Dhaka';


-- Better

EXPLAIN ANALYZE

SELECT

    driver_id,
    full_name,
    city,
    driver_status

FROM drivers

WHERE city = 'Dhaka';


/*
Why?

SELECT * may read unnecessary columns.

Selecting only required columns can reduce
I/O and memory usage.
*/


/*
=========================================================
SECTION 18
Avoid Function on Indexed Date Column
=========================================================
*/


-- Less index-friendly

EXPLAIN ANALYZE

SELECT

    SUM(total_income)

FROM earnings

WHERE DATE_TRUNC('month', earning_date)
      = DATE '2025-01-01';


-- Better range condition

EXPLAIN ANALYZE

SELECT

    SUM(total_income)

FROM earnings

WHERE earning_date >= DATE '2025-01-01'

AND earning_date < DATE '2025-02-01';


/*
The second query is generally more index-friendly
because the indexed column is not wrapped inside a function.
*/


/*
=========================================================
SECTION 19
COUNT Optimization
=========================================================
*/


-- General count

EXPLAIN ANALYZE

SELECT COUNT(*)

FROM trips;


-- Filtered count

EXPLAIN ANALYZE

SELECT COUNT(*)

FROM trips

WHERE completed = TRUE;


/*
Partial index may help the second query depending
on table size and data distribution.
*/


/*
=========================================================
SECTION 20
ORDER BY + LIMIT
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,

    SUM(total_income) AS total_income

FROM earnings

GROUP BY driver_id

ORDER BY total_income DESC

LIMIT 10;


/*
Note:

The aggregation itself may still require scanning
many rows. An index on driver_id helps grouping/JOINs,
but it does not automatically make SUM(total_income)
ORDER BY DESC instantaneous.
*/


/*
=========================================================
SECTION 21
VIEW Performance Check
=========================================================
*/

EXPLAIN ANALYZE

SELECT *

FROM vw_driver_performance

ORDER BY total_income DESC

LIMIT 10;


/*
Important:

A normal PostgreSQL VIEW does not store the result.

PostgreSQL expands the underlying query during execution.

Therefore indexes on the underlying tables still matter.
*/


/*
=========================================================
SECTION 22
Burnout View Performance
=========================================================
*/

EXPLAIN ANALYZE

SELECT

    driver_id,
    full_name,
    burnout_score

FROM vw_driver_burnout_score

ORDER BY burnout_score DESC

LIMIT 20;


/*
Check the execution plan to identify expensive
joins, scans and aggregations.
*/


/*
=========================================================
SECTION 23
Update Statistics
=========================================================
*/

ANALYZE trips;

ANALYZE earnings;

ANALYZE ratings;

ANALYZE complaints;

ANALYZE daily_driver_metrics;

ANALYZE drivers;

ANALYZE vehicles;

ANALYZE churn_labels;


/*
ANALYZE updates PostgreSQL statistics.

This helps the query planner choose better
execution plans.
*/


/*
=========================================================
SECTION 24
Check Existing Indexes
=========================================================
*/

SELECT

    schemaname,
    tablename,
    indexname,
    indexdef

FROM pg_indexes

WHERE schemaname = 'public'

ORDER BY

    tablename,
    indexname;


/*
=========================================================
SECTION 25
Check Table Sizes
=========================================================
*/

SELECT

    relname AS table_name,

    pg_size_pretty(
        pg_total_relation_size(relid)
    ) AS total_size

FROM pg_catalog.pg_statio_user_tables

ORDER BY

    pg_total_relation_size(relid) DESC;


/*
=========================================================
SECTION 26
Check Index Usage
=========================================================
*/

SELECT

    relname AS table_name,

    indexrelname AS index_name,

    idx_scan AS index_scans,

    idx_tup_read AS tuples_read,

    idx_tup_fetch AS tuples_fetched

FROM pg_stat_user_indexes

ORDER BY

    idx_scan DESC;


/*
=========================================================
SECTION 27
Find Rarely Used Indexes
=========================================================
*/

SELECT

    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan

FROM pg_stat_user_indexes

WHERE idx_scan = 0

ORDER BY

    relname;


/*
IMPORTANT:

Do NOT immediately drop an unused index.

The statistics may have been reset recently,
or the index may be used by occasional queries.
*/


/*
=========================================================
SECTION 28
Check Sequential Scans
=========================================================
*/

SELECT

    relname AS table_name,

    seq_scan,

    seq_tup_read,

    idx_scan

FROM pg_stat_user_tables

ORDER BY

    seq_tup_read DESC;


/*
High sequential scan is not automatically bad.

For small tables PostgreSQL may correctly choose
Sequential Scan instead of Index Scan.
*/


/*
=========================================================
SECTION 29
Full Query Plan
=========================================================
*/

EXPLAIN
(
    ANALYZE,
    BUFFERS,
    VERBOSE
)

SELECT

    d.city,

    SUM(e.total_income) AS revenue

FROM drivers d

JOIN earnings e

ON d.driver_id = e.driver_id

WHERE e.earning_date >= DATE '2025-01-01'

AND e.earning_date < DATE '2025-02-01'

GROUP BY d.city;


/*
BUFFERS helps identify:

- Shared hit
- Shared read
- I/O pressure
- Cache behavior
*/


/*
=========================================================
SECTION 30
Optimization Checklist
=========================================================

Before optimization:

1. EXPLAIN ANALYZE
2. Check Execution Time
3. Check Sequential Scan
4. Check Join Strategy
5. Check Rows Removed by Filter
6. Check Buffers

Then:

7. Create appropriate index
8. ANALYZE table
9. Run EXPLAIN ANALYZE again
10. Compare execution plans
11. Compare execution time
12. Check whether the index is actually used

=========================================================
END OF QUERY OPTIMIZATION
=========================================================
*/