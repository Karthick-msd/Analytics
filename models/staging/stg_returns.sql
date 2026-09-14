
with source as (

    select * from {{ ref('bronze_returns') }}

),

deduped as (
    select
        *,
        row_number() over (
            partition by return_id
            order by _bronze_loaded_at desc
        ) as _rn
    from source
),

cleaned as (
    select
        cast(return_id as bigint)          as return_id,
        cast(order_id as bigint)           as order_id,

        -- return_date is genuinely NULL for a "Pending" return -- that's not
        -- missing data, it's a business state (not processed yet). We keep
        -- it NULL rather than inventing a fake date; the status column already
        -- tells the true story.
        cast(return_date as date)          as return_date,
        initcap(trim(return_reason))              as return_reason,
        regexp_replace({{parse_null('refund_amount')}} , '[^0-9.-]','') as refund_amount,
        initcap(trim(return_status))       as return_status

    from deduped
    where _rn = 1
)

select * from cleaned