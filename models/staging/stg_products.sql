
with source as (

    select * from {{ ref('bronze_products') }}

),

deduped as (
    -- For a dimension table this dedup matters MORE than for a fact table:
    -- if bronze ever double-lands a product row, this is what stops a
    -- fan-out (row multiplication) the moment anyone joins fact tables to it.
    select
        *,
        row_number() over (
            partition by product_id
            order by _bronze_loaded_at desc
        ) as _rn
    from source
),

cleaned as (
    select
        cast(product_id as bigint)        as product_id_from_products,
        trim(product_name)                as product_name,
        initcap(trim(category))           as category,
        initcap(trim(subcategory))       as sub_category,
        cast(price as decimal(10,2)) as price,

        cast(cost as decimal(10,2))  as cost,
        cast(supplier_id as bigint) as supplier_id,
    
        (cast(price as decimal(10,2)) - cast(cost as decimal(10,2))) as unit_margin,
        (cast(price as decimal(10,2)) - cast(cost as decimal(10,2)))
            / nullif(cast(price as decimal(10,2)), 0)                    as margin_pct

    from deduped
    where _rn = 1
)

select * from cleaned