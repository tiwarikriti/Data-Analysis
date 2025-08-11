-- find top10 higest revenue generating products
SELECT product_id, sum(sale_price) as sales from df_orders group by product_id order by sales desc limit 10;
-- find top5 highest selling product in each region
With cte as(
	SELECT region, product_id, sum(sale_price) as sales, row_number() over(partition by region order by sum(sale_price) desc) as rn
	from df_orders group by region, product_id)
select *
from cte where rn <=5;
-- find MoM growth for 2022 and 2023
with cte as (select year(order_date) as order_year, month(order_date) as order_month, sum(sale_price) as sales
from df_orders group by order_year, order_month order by order_year, order_month)
select order_month, 
sum(case when order_year = 2022 then sales else 0 end) as 2022_sales, 
sum(case when order_year = 2023 then sales else 0 end) as 2023_sales
from cte group by order_month order by order_month;
-- for each category which month had the highest sales
with cte as ( select date_format(order_date, '%Y%m') as order_year_month, category, 
sum(sale_price) as sales, 
row_number() over(partition by category order by sum(sale_price) desc) as rn
from df_orders group by order_year_month, category)
select category, order_year_month, sales from cte where rn = 1;
-- which sub-category has the highest growth by profit percent in 2023 compare to 2022
with cte1 as (select year(order_date) as order_year, sub_category, sum(sale_price) as sales
from df_orders group by order_year, sub_category order by order_year, sub_category),
cte2 as(select sub_category, 
sum(case when order_year = 2022 then sales else 0 end) as 2022_sales, 
sum(case when order_year = 2023 then sales else 0 end) as 2023_sales
from cte1 group by sub_category order by sub_category)
select sub_category, ((2023_sales - 2022_sales)*100/2022_sales) as profits from cte2 order by profits desc limit 1