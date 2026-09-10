
-- Enrichment pattern: dimension (product) fanned OUT across warehouses
-- (inventory is captured per-warehouse). We deliberately do NOT collapse to
-- one row per product here -- "stock health per warehouse" is a legitimate
-- grain on its own, and collapsing it early would destroy information a
-- warehouse-ops gold model will need later.
with products as (

    select * from {{ ref('stg_products') }}

),

inventory as (

    select * from {{ ref('stg_inventory') }}

)

select
    i.inventory_id,
    i.product_id_from_inventory,
    i.warehouse_id,
    i.quantity_on_hand,
    i.reorder_level,
    i.is_below_reorder_level,
    i.last_restock_date,

    p.product_id_from_products,
    p.product_name,
    p.category,
    p.sub_category,
    p.price,
    p.cost,
    p.supplier_id,
    i.quantity_on_hand * p.cost as inventory_value_at_cost

from inventory i
inner join products p
    on i.product_id_from_inventory = p.product_id_from_products