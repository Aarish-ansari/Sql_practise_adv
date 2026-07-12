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

