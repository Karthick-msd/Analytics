
with source as (

    select * from {{ ref('bronze_date') }}

)

select
    cast(date_key as int)          as date_key,
    cast(full_date as date)       as full_date,
    cast(day as int) as day , 
    cast(month as int)            as month,
    trim(month_name)              as month_name,

    trim(quarter)                 as quarter,
        cast(year as int)             as year,

    trim(day_of_week)             as day_of_week,
    cast(is_weekend as boolean)   as is_weekend

from source