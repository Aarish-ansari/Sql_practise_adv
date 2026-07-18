
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
SELECT
    ot.seller_id,
    MONTH(o.order_purchase_timestamp) AS month_no,
    MONTHNAME(o.order_purchase_timestamp) AS month_name,
    SUM(ot.price + ot.freight_value) AS revenue
FROM orders o
JOIN order_items ot
    ON o.order_id = ot.order_id
GROUP BY
    ot.seller_id,
    month_no,month_name
ORDER BY
    month_no desc;
select DISTINCT count(seller_id) from order_items;
SELECT
    oi.seller_id,
    GROUP_CONCAT(DISTINCT p.product_category_name
                 ORDER BY p.product_category_name SEPARATOR "|") AS categories,
    COUNT(DISTINCT p.product_category_name) AS category_count
FROM order_items AS oi
JOIN products AS p
ON oi.product_id = p.product_id
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT p.product_category_name) > 1
ORDER BY category_count DESC;
select ot.seller_id , 
group_concat(DISTINCT p.product_category_name order BY p.product_category_name) as Category ,
count(DISTINCT p.product_category_name) as Count
from order_items as ot 
join products as p 
on p.product_id=ot.product_id
group BY ot.seller_id
order by Count desc;
select review_score from reviews;
SELECT
    p.product_category_name AS product_name,
    SUM(ot.price + ot.freight_value) AS total_revenue,
    AVG(r.review_score) AS avg_rating
FROM order_items AS ot
JOIN products AS p
    ON ot.product_id = p.product_id
JOIN reviews AS r
    ON ot.order_id = r.order_id
GROUP BY p.product_category_name
HAVING AVG(r.review_score) < 3.5
ORDER BY total_revenue DESC;
select * from (
    SELECT
       p.product_category_name,
        oi.product_id,
        SUM(oi.price + oi.freight_value) AS revenue,
        RANK() OVER(
            PARTITION BY p.product_category_name
            ORDER BY SUM(oi.price + oi.freight_value) DESC
        ) AS rnk
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY
        p.product_category_name,
        oi.product_id 
) t
WHERE t.rnk <= 3;

WITH cte AS (
    SELECT
        ot.order_id,
        p.product_category_name AS product_category,
        SUM(ot.price + ot.freight_value) AS order_value
    FROM order_items AS ot
    JOIN products AS p
        ON ot.product_id = p.product_id
    GROUP BY
        ot.order_id,
        p.product_category_name
)

SELECT
    product_category,
    AVG(order_value) AS AOV
FROM cte
GROUP BY product_category;
SELECT
    oi.seller_id,
    AVG(DATEDIFF(o.order_delivered_customer_date,
                 o.order_estimated_delivery_date)) AS avg_delivery_delay
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
ORDER BY avg_delivery_delay DESC;

select c.customer_state  as 'State', 
avg(datediff(o.order_delivered_customer_date,o.order_purchase_timestamp)) as avg_time
from orders as o 
join customers as c
on c.customer_id=o.customer_id
GROUP BY c.customer_state 
order by avg_time DESC;

SELECT *
FROM (
    SELECT
        p.product_category_name,
        c.customer_state AS state,
        COUNT(*) AS purchase_count,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_state
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items ot
        ON o.order_id = ot.order_id
    JOIN products p
        ON ot.product_id = p.product_id
    GROUP BY
        p.product_category_name,
        c.customer_state
) AS t
WHERE rnk = 1
WITH cte AS (
    SELECT
        ot.order_id,
        p.product_category_name AS product_category,
        SUM(ot.price + ot.freight_value) AS order_value
    FROM order_items AS ot
    JOIN products AS p
        ON ot.product_id = p.product_id
    GROUP BY
        ot.order_id,
        p.product_category_name
)

SELECT
    product_category,
    AVG(order_value) AS AOV
FROM cte
GROUP BY product_category;
