
-- Enrichment pattern: one order fact, THREE related facts fanning in
-- (payments, returns) -- classic "case journey" shape, like tracing a single
-- support ticket through creation -> resolution -> feedback in your ops world.
-- We aggregate payments/returns to one row per order FIRST, then join,
-- specifically to prevent fan-out (a single order with 2 partial payments and
-- 1 return should not silently become 2 or 3 duplicated order rows).
with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

returns as (
    select * from {{ ref('stg_returns') }}
),

payment_agg as (
    select
        order_id,
        sum(amount_paid)                                                     as total_amount_paid,
        count(*)                                                             as payment_count,
        max(payment_date)                                                    as last_payment_date,
        sum(case when payment_status = 'Success' then 1 else 0 end)          as successful_payment_count,
        sum(case when payment_status = 'Failed'  then 1 else 0 end)          as failed_payment_count
    from payments
    group by order_id
),

return_agg as (
    select
        order_id,
        count(*)                                                             as return_count,
        sum(refund_amount)                                                   as total_refund_amount,
        sum(case when return_status = 'Approved' then 1 else 0 end)          as approved_return_count,
        sum(case when return_status = 'Pending'  then 1 else 0 end)          as pending_return_count
    from returns
    group by order_id
)

select
    o.*,
    coalesce(p.total_amount_paid, 0)          as total_amount_paid,
    coalesce(p.payment_count, 0)              as payment_count,
    p.last_payment_date,
    coalesce(p.successful_payment_count, 0)   as successful_payment_count,
    coalesce(p.failed_payment_count, 0)       as failed_payment_count,
    coalesce(r.return_count, 0)               as return_count,
    coalesce(r.total_refund_amount, 0)        as total_refund_amount,
    coalesce(r.approved_return_count, 0)      as approved_return_count,
    coalesce(r.pending_return_count, 0)       as pending_return_count,

    -- Net revenue = what actually stuck, after refunds. This single column is
    -- the whole reason this model exists -- no gold-layer report should ever
    -- have to re-derive it from three separate tables.
    coalesce(p.total_amount_paid, 0) - coalesce(r.total_refund_amount, 0) as net_revenue

from orders o
left join payment_agg p on o.order_id = p.order_id
left join return_agg  r on o.order_id = r.order_id