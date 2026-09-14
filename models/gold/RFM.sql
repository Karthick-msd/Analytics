{{
    config(
        materialized='table'
    )
}}


with orders_grain AS (
    SELECT DISTINCT
        customer_id,
        order_id,
        order_date
    FROM stg_orders
),

-- RECENCY: true customer grain. One row per customer, last order date across
-- ALL their orders (not per order, which is what the original grouped by). 

recency AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date,
        DATEDIFF(CURRENT_DATE(), MAX(order_date)) AS recency_days
    FROM orders_grain
    GROUP BY customer_id
),

-- FREQUENCY / CADENCE: window function now runs over deduped order-grain rows,
-- so LEAD() correctly finds the NEXT ORDER's date, not the next line-item's.
order_gaps AS (
    SELECT
        customer_id,
        order_id,
        order_date AS this_order_date,
        LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date
    FROM orders_grain
),

order_gaps_calc AS (
    SELECT
        *,
        DATEDIFF(next_order_date, this_order_date) AS days_to_next_order
    FROM order_gaps
),

-- Classic RFM Frequency = order COUNT per customer.
-- avg_days_between_orders is a separate, complementary cadence metric -
-- keep both, don't conflate them under one column name.
frequency AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders,
        AVG(days_to_next_order) AS avg_days_between_orders
    FROM order_gaps_calc
    GROUP BY customer_id
),

-- MONETARY: aggregate to order grain first, then to customer grain.
-- Uses SUM here on the assumption total_amount is genuinely line-item-level.
-- Flip to MAX()/ANY_VALUE() if the grain check above says otherwise.
orders_value AS (
    SELECT
        customer_id,
        order_id,
        SUM(COALESCE(TRY_CAST(total_amount AS DECIMAL(18,2)), 0)) AS order_amount
    FROM stg_orders
    GROUP BY customer_id, order_id
),

returns_value AS (
    SELECT
        order_id,
        SUM(COALESCE(TRY_CAST(refund_amount AS DECIMAL(18,2)), 0)) AS refund_amount
    FROM stg_returns
    GROUP BY order_id
),

order_net_value AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_amount - COALESCE(r.refund_amount, 0) AS net_order_value
    FROM orders_value o
    LEFT JOIN returns_value r
        ON o.order_id = r.order_id
),

monetary AS (
    SELECT
        customer_id,
        SUM(net_order_value) AS total_monetary_value
    FROM order_net_value
    GROUP BY customer_id
)

-- LAYER 4: every CTE above is now genuinely one-row-per-customer, so joining
-- on customer_id alone is correct here - it wasn't correct in the original
-- because diff_check/recency weren't actually at that grain yet.
SELECT
    r.customer_id,
    r.last_order_date,
    r.recency_days,
    f.total_orders,
    f.avg_days_between_orders,
    m.total_monetary_value
FROM recency r
JOIN frequency f
    ON r.customer_id = f.customer_id
JOIN monetary m
    ON r.customer_id = m.customer_id