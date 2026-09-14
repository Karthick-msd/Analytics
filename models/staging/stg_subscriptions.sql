

with source as (

    select * from {{ ref('bronze_subscriptions') }}

),

deduped as (
    select
        *,
        row_number() over (
            partition by subscription_id
            order by _bronze_loaded_at desc
        ) as _rn
    from source
),

cleaned as (
    select
        cast(subscription_id as bigint)  as subscription_id,
        cast(customer_id as bigint)      as customer_id,
        initcap(trim(plan_type))              as plan,
        cast(start_date as date)         as start_date,

        -- Null end_date = still active. Same principle as return_date above:
        -- a NULL here is meaningful business state, not a data quality gap.
        cast(end_date as date)           as end_date,
        cast(mrr as decimal(10,2))       as mrr,
        initcap(trim(status))            as subscription_status,
        case
            when end_date is null then true
            else false
        end as is_currently_active

    from deduped
    where _rn = 1
)

select * from cleaned