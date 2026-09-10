
with source as (

    select * from {{ ref('bronze_marketing_campaigns') }}

),

deduped as (
    select
        *,
        row_number() over (
            partition by campaign_id
            order by _bronze_loaded_at desc
        ) as _rn
    from source
),

cleaned as (
    select
        cast(campaign_id as bigint)          as campaign_id,
        trim(campaign_name)                  as campaign_name,
        initcap(trim(channel))         as channel,
        cast(start_date as date)             as start_date,
        cast(end_date as date)               as end_date,
        cast(budget as decimal(12,2))        as budget,
        initcap(trim(target_segment))        as target_segment
        
    from deduped
    where _rn = 1
)

select * from cleaned