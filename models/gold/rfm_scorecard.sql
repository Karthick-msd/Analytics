{{
    config(
        materialized='table'
    )
}}

WITH base AS (
    SELECT * FROM {{ ref('RFM') }}
),
 
scored AS (
    SELECT
        *,
        -- NTILE splits customers into 5 equal-sized buckets ordered by the metric.
        -- For recency_days, LOWER is better (more recent) -> ascending order,
        -- so bucket 5 = most recent. For frequency/monetary, HIGHER is
        -- better -> also ascending, bucket 5 = highest.
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY total_orders ASC)   AS f_score,
        NTILE(5) OVER (ORDER BY total_monetary_value ASC) AS m_score
    FROM base
)
 
SELECT
    *,
    (r_score + f_score + m_score) AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New / Promising'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating / Lost'
        ELSE 'Needs Attention'
    END AS segment
FROM scored
 


