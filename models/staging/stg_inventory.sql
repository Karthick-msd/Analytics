with source as (

    select * from {{ ref('bronze_inventory') }}

),

deduped as (
    select
        *,
        row_number() over (
            partition by inventory_id
            order by _bronze_loaded_at desc
        ) as _rn
    from source
),

cleaned as (
    select
        cast(inventory_id as bigint)          as inventory_id,
        cast(product_id as bigint)            as product_id_from_inventory,
        cast(warehouse_id as bigint)              as warehouse_id,
        cast(quantity_on_hand as int)              as quantity_on_hand,
        cast(reorder_level as int)            as reorder_level,
        cast(last_restock_date as date)     as last_restock_date,

case
    when quantity_on_hand is null or reorder_level is null then null
    when quantity_on_hand < reorder_level then true
    else false
end as is_below_reorder_level

    from deduped
    where _rn = 1
)

select * from cleaned
