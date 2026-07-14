
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

retention rate of customer Month per month 
WITH customer_month AS (
SELECT DISTINCT
c.customer_unique_id,
DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m-01')
AS Purchase_Month
FROM orders o
JOIN customers c
ON o.customer_id=c.customer_id
),
customer_history AS (
SELECT *,
LAG(Purchase_Month)
OVER(
PARTITION BY customer_unique_id
ORDER BY Purchase_Month
) AS Previous_Month
FROM customer_month
),
retention AS (
SELECT
Purchase_Month,
COUNT(*) AS Retained_Customers
FROM customer_history
WHERE TIMESTAMPDIFF(
MONTH,
Previous_Month,
Purchase_Month
)=1
GROUP BY Purchase_Month
),
monthly_customer AS (
SELECT
Purchase_Month,
COUNT(DISTINCT customer_unique_id)
AS Total_Customers
FROM customer_month
GROUP BY Purchase_Month
)
SELECT
m.Purchase_Month,
m.Total_Customers,
COALESCE(r.Retained_Customers,0)
AS Retained_Customers,
ROUND(
COALESCE(r.Retained_Customers,0)
/
LAG(m.Total_Customers)
OVER(ORDER BY m.Purchase_Month)
*100
,2)
AS Retention_Rate
FROM monthly_customer m
LEFT JOIN retention r
ON m.Purchase_Month=r.Purchase_Month
ORDER BY Purchase_Month;

select year(o.order_purchase_timestamp) as 'year', monthname(o.order_purchase_timestamp) as Month, 
ot.seller_id , sum(ot.price+ot.freight_value) as 'Revenue'
from order_items as ot 
JOIN orders as o 
on o.order_id=ot.order_id
GROUP BY year(o.order_purchase_timestamp),
month(o.order_purchase_timestamp),
monthname(o.order_purchase_timestamp),
ot.seller_id
order by year(o.order_purchase_timestamp),
month(o.order_purchase_timestamp),
monthname(o.order_purchase_timestamp);
