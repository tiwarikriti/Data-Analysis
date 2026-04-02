-- 1 What are the top three products sold each month

with cte as (select date_format(timestamp, '%Y-%m') as month, product_id, count(product_id) as cnt, 
dense_rank() over(partition by date_format(timestamp, '%Y-%m') order by count(product_id) desc) as ranks from product_events 
where event = "Buy" group by month, product_id)
select month, product_id, cnt from cte where ranks <= 3 order by month, ranks;

-- 2 For each month, that is the count of users who added an item to the cart & count of users who bought that item within 3 days of adding it to the cart

with atc as(
select user_id, product_id, timestamp as atc_time, date_format(timestamp, '%Y-%m') as month from product_events where event = "ATC"),
buy as(
select user_id, product_id, timestamp as buy_time from product_events where event = "Buy"),
converted as(
select a.user_id, a.month,
max(case when b.buy_time >= a.atc_time and timestampdiff(day,a.atc_time, b.buy_time)<=3 then 1 else 0 end) as bought_within_3d
from atc a left join buy b
on a.user_id = b.user_id
and a.product_id = b.product_id
group by a.user_id, a.atc_time, a.month)
Select month, count(distinct(user_id)) as atc_cnt, count(distinct(case when bought_within_3d = 1 then user_id end)) as buy_cnt
from converted group by month order by month;

-- 3 For each month, what is the M1 retention of users after their first order. A user is considered as retained in M1 if they have purchased a product between 30 to 60 days of their first order

with first_order as(
select user_id,
min(timestamp) as first_order_time,
date_format(min(timestamp), '%Y-%m') as first_order_month
from product_events where event = 'Buy' group by user_id),
m1_buyers as(
select distinct(p.user_id)
from product_events p
join first_order f on p.user_id = f.user_id
where p.event = 'Buy'
and p.timestamp > f.first_order_time
and timestampdiff(day, f.first_order_time, p.timestamp) between 30 and 60)
select f.first_order_month,
count(distinct(f.user_id)) as total_first_time_buyers,
count(distinct(m.user_id)) as m1_retained,
round(count(distinct(m.user_id))/count(distinct(f.user_id))*100, 2) as m1_retained_prt
from first_order f left join m1_buyers m
on f.user_id = m.user_id
group by f.first_order_month order by f.first_order_month