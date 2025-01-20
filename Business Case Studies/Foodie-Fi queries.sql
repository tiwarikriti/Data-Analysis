-- How many customers has Foodie-Fi ever had?
-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- What is the number and percentage of customer plans after their initial free trial?
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- How many customers have upgraded to an annual plan in 2020?
-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
-- 1. 
SELECT count(distinct customer_id) as total_customers FROM foodie_fi.subscriptions;
-- 2.
SELECT to_char(date_trunc('month', s.start_date), 'MM') as month_num, 
count(distinct s.customer_id) as monthly_trial_plans 
from foodie_fi.subscriptions s where s.plan_id = 0 
group by month_num order by month_num;
-- 3.
Select s.plan_id, count(s.plan_id) as count_of_events 
from foodie_fi.subscriptions s where s.start_date > '2020-12-31' 
group by s.plan_id order by count_of_events desc;
-- 4.
 select count(distinct s.customer_id) as total_customers,
 count(case when p.plan_name  = 'churn' then 1 end) as churned_customers,
 round((count(case when p.plan_name  = 'churn' then 1 end) ::numeric/count(distinct s.customer_id)*100), 1) as churn_rate 
 from foodie_fi.subscriptions s join foodie_fi.plans p on s.plan_id = p.plan_id 
 -- 5.
 WITH row_num AS(
  SELECT 
    s.customer_id, s.plan_id, s.start_date, 
    row_number() OVER(PARTITION BY customer_id ORDER BY plan_id) AS rn 
FROM foodie_fi.subscriptions s)
SELECT COUNT(CASE WHEN plan_id = 4 AND rn = 2 THEN 1 END) AS churn_customers,
ROUND((COUNT(CASE WHEN plan_id = 4 AND rn = 2 THEN 1 END):: numeric/COUNT(DISTINCT customer_id) * 100), 1) AS percent__churned_cust FROM row_num;
-- 6
WITH ranking as(
  SELECT s.customer_id, s.plan_id, s.start_date,
  RANK() OVER(PARTITION BY s.customer_id ORDER BY s.start_date) as ranks
  FROM foodie_fi.subscriptions s)
SELECT p.plan_id, p.plan_name, COUNT(p.plan_id) AS nxt_plan,
ROUND((COUNT(p.plan_id)::numeric/(SELECT COUNT(plan_id) FROM ranking WHERE ranks = 2)*100), 1)
AS percent_of_conversion
FROM ranking r JOIN foodie_fi.plans p
ON r.plan_id = p.plan_id
WHERE ranks = 2
GROUP BY p.plan_id, p.plan_name
ORDER BY p.plan_id
-- 7
with ranking as(
  select plan_id, customer_id, start_date, 
  rank() over(partition by customer_id order by start_date desc) as ranks
  from foodie_fi.subscriptions
  where start_date <= '2020-12-31')
select p.plan_name, count(r.customer_id) as customer_count,
round(count(r.customer_id)::numeric/ (select count(customer_id) from ranking where ranks = 1) *100, 1) as customer_percentage
from ranking r join foodie_fi.plans p 
on r.plan_id = p.plan_id
where ranks = 1
group by p.plan_name, p.plan_id
order by customer_count desc
-- 8
SELECT count(DISTINCT s.customer_id) AS upgraded_customers
FROM foodie_fi.subscriptions s
WHERE s.plan_id = 3
	AND extract(year FROM s.start_date) = '2020'

-- 9
with first_plan as(select customer_id, start_date as first_date from foodie_fi.subscriptions 
where plan_id = 0),
annual_plan as(select customer_id, start_date as upgrade_date from foodie_fi.subscriptions 
where plan_id = 3)
select round(avg(a.upgrade_date - f.first_date)) as avg_num_of_days from first_plan f join annual_plan a on f.customer_id = a.customer_id
-- 10
WITH first_plan AS (
    SELECT customer_id, start_date AS first_date 
    FROM foodie_fi.subscriptions 
    WHERE plan_id = 0
),
annual_plan AS (
    SELECT customer_id, start_date AS upgrade_date 
    FROM foodie_fi.subscriptions 
    WHERE plan_id = 3
),
bucketed_data AS (
    SELECT 
        width_bucket(a.upgrade_date - f.first_date, 0, 360, 12) AS period_bucket,
        a.upgrade_date - f.first_date AS days_difference
    FROM 
        first_plan f 
        JOIN annual_plan a 
        ON f.customer_id = a.customer_id
)
SELECT 
	(period_bucket - 1) * 30 || '-' || period_bucket * 30 AS range,
    COUNT(*) AS customer_count
FROM 
    bucketed_data
GROUP BY 
    period_bucket
ORDER BY 
    period_bucket;
-- 11
with next_plan as(
  select customer_id, plan_id, start_date,
  lead(plan_id,1) over(partition by customer_id order by plan_id) as nxt_plan
  from foodie_fi.subscriptions)
select count(*) as downgraded_customers 
from next_plan
where start_date <= '2020-12-31'
and plan_id = 2
and nxt_plan = 1
