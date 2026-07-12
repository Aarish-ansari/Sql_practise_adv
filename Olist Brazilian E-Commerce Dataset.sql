
use ecommerce;
SELECT * FROM ecommerce.order_items;
WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS Year,
        MONTH(o.order_purchase_timestamp) AS Month_No,
        MONTHNAME(o.order_purchase_timestamp) AS Month,
        SUM(p.payment_value) AS Revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp),
        MONTHNAME(o.order_purchase_timestamp)
)

SELECT
    Year,
    Month,
    Revenue,
    LAG(Revenue) OVER(
        ORDER BY Year, Month_No
    ) AS Previous_Month_Revenue,

    ROUND(
        (
            Revenue -
            LAG(Revenue) OVER(
                ORDER BY Year, Month_No
            )
        )
        /
        LAG(Revenue) OVER(
            ORDER BY Year, Month_No
        ) * 100,
        2
    ) AS MoM_Growth_Percentage

FROM monthly_revenue
ORDER BY Year, Month_No;

select p.product_category_name as Categoty_Name , round(sum(ot.price+ot.freight_value),2) as "total_Price"
from products as p 
join order_items as ot 
on p.product_id=ot.product_id
GROUP BY p.product_category_name
order by sum(ot.price+ot.freight_value) DESC
limit 5;
with cte as (
select year(o.order_purchase_timestamp) as 'Year',quarter(o.order_purchase_timestamp) as "quarter" ,
round(sum(ot.price+ot.freight_value),2) as 'Revenue'
from orders as o 
join order_items as ot 
on o.order_id=ot.order_id
group by year(order_purchase_timestamp),quarter(order_purchase_timestamp))
select * ,
round(
((Revenue- lag(Revenue) over(order by Year,quarter  ))/
lag(Revenue) over(order by Year,quarter ))*100,2) as 'Growth_Per' 
from cte
order  by Year,quarter;
with cte as (
select date(o.order_purchase_timestamp)  as "Date" ,
round(sum(ot.price+ot.freight_value),2) as 'Revenue'
from orders as o 
join order_items as ot 
on o.order_id=ot.order_id
group by date(o.order_purchase_timestamp))
select *,sum(Revenue) over(order by Date ROWS BETWEEN UNBOUNDED PRECEDING and CURRENT ROW ) as "Cum_Revnue"
from cte 
order by Date;

with monthly_r as (
select year(o.order_purchase_timestamp) as 'Year', 
month(o.order_purchase_timestamp) as 'Month_no',
monthname(o.order_purchase_timestamp) as "Month" ,
round(sum(ot.price+ot.freight_value),2) as 'Revenue'
from orders as o 
join order_items as ot 
on o.order_id=ot.order_id
group by year(o.order_purchase_timestamp),month(o.order_purchase_timestamp),monthname(o.order_purchase_timestamp)),
cte as (
select * ,
(Revenue- lag(Revenue) over(order by Year,Month_no)) as 'Diff_revenue'
from monthly_r ) 
select * from cte 
where Diff_revenue<0 
order by Diff_revenue 
limit 1;
with cte as (
select year(o.order_purchase_timestamp) as 'year', p.product_category_name as 'Category_Name' ,
round(sum(ot.price+ot.freight_value),2) as 'Revenue'
from order_items as ot 
join orders as o 
on o.order_id=ot.order_id
join products as p 
on p.product_id=ot.product_id
GROUP BY year(o.order_purchase_timestamp),p.product_category_name),
cte2 as (
SELECT *,(Revenue/sum(Revenue) over(PARTITION BY year))*100 as "contribution" 
from cte)
select * from (select *, ROW_NUMBER() OVER(PARTITION BY year order by contribution desc) as 'Max_contri' 
from cte2 )  as t 
where t.Max_contri=1;

select s.seller_id as 'Saller', 
sum(ot.price+ot.freight_value) as "Revenue" 
from order_items as ot
join sellers as s 
on s.seller_id=ot.seller_id
GROUP BY s.seller_id 
order by Revenue desc;

