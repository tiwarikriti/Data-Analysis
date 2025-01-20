

-- 1. What is the total amount each customer spent at the restaurant?
	select s.customer_id, sum(me.price) as total_amt 
	from dannys_diner.sales s join dannys_diner.menu me on s.product_id = me.product_id 
	group by s.customer_id;
-- 2. How many days has each customer visited the restaurant?
	select s.customer_id, count(distinct(s.order_date)) as days 
	from dannys_diner.sales s
	group by s.customer_id;
-- 3. What was the first item from the menu purchased by each customer?
	with cte as (select s.customer_id, s.product_id, 
    row_number() over (partition by s.customer_id order by s.order_date asc) as rownum 
    from dannys_diner.sales s)
	select customer_id, product_id from cte where rownum = 1;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
	select product_id, max(prod) from 
    (select s.product_id, count(s.product_id) as prod 
    from dannys_diner.sales s
    group by s.product_id)as j 
    group by j.product_id Limit 1; 
-- 5. Which item was the most popular for each customer?
	WITH cte AS ( SELECT s.customer_id, s.product_id, COUNT(ds.product_id) AS prod_count
		FROM dannys_diner.sales s
		GROUP BY s.customer_id, s.product_id
),
ranked_cte AS ( SELECT customer_id, product_id, prod_count,
        RANK() OVER (PARTITION BY customer_id ORDER BY prod_count DESC) AS rank
    FROM cte
)
SELECT customer_id, product_id, prod_count
FROM ranked_cte
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
with cte as(
  select s.customer_id, s.order_date, me.product_name,
  row_number() over(partition by s.customer_id order by s.order_date) as rn 
  from dannys_diner.sales s join dannys_diner.menu me 
  on s.product_id = me.product_id
  join dannys_diner.members m
  on s.customer_id = m.customer_id
  where s.order_date >= m.join_date
  order by s.order_date)
select customer_id, product_name from cte where rn = 1;
-- 7. Which item was purchased just before the customer became a member?
with previous_orders as(
  select s.customer_id, s.order_date, m.join_date, me.product_name,
  lag(me.product_name) over(partition by s.customer_id order by s.order_date) as prev_order
  from dannys_diner.sales s join dannys_diner.menu me 
  on s.product_id = me.product_id
  join dannys_diner.members m
  on s.customer_id = m.customer_id
  order by s.order_date),
before_member as(
  select customer_id, order_date, prev_order,row_number() over(partition by customer_id order by order_date) as rn from previous_orders where order_date >= join_date)
select cte2.customer_id, cte2.prev_order from before_member where rn =1;
-- 8. What is the total amount spent for each member before they became a member?
select s.customer_id, sum(me.price) 
from dannys_diner.sales s join dannys_diner.menu me
on s.product_id = me.product_id
join dannys_diner.members m on s.customer_id = m.customer_id
where s.order_date < m.join_date
group by s.customer_id
order by s.customer_id
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with amount as(
select s.customer_id, me.product_name, sum(me.price) as amt_spent
from dannys_diner.sales s join dannys_diner.menu me
on s.product_id = me.product_id
group by s.customer_id, me.product_name
order by s.customer_id),
points as(
select customer_id, amt_spent, product_name, case when product_name = 'curry' or product_name = 'ramen' then amt_spent
when product_name = 'sushi' then 2* amt_spent end as points_earned from amount)

select customer_id, sum(points_earned) as total_points from points
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with amount as(
select s.customer_id, me.product_name, 
sum(me.price) as amt_spent, s.order_date,
m.join_date
from dannys_diner.sales s join dannys_diner.menu me
on s.product_id = me.product_id join dannys_diner.members m on s.customer_id = m.customer_id
group by s.customer_id, me.product_name, s.order_date, m.join_date
order by s.customer_id),
points as(
select customer_id, amt_spent, product_name, order_date, join_date, case
when order_date between join_date and join_date + interval '7 days' then 20*amt_spent
when product_name = 'sushi' then 20* amt_spent
else 10*amt_spent end as points_earned from amount)

select customer_id, sum(points_earned) as total_points from points
where order_date between'2021-01-01' and '2021-01-31'
group by customer_id




