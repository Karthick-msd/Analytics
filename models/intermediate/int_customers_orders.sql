with deduped_customers as (
select * 
from ( 
   select *,
   row_number() over(partition by customer_id order by signup_date_parsed desc) as rn
   from {{ref('stg_customers')}} 
) 
where rn = 1 
),
orders as (
   select * from 
   {{ref('stg_orders')}}
),

enriched as (
select 
        o.order_id,
        o.customer_id,
        o.product_id,
        o.quantity,
        o.order_date,
        o.order_status,
        o.total_amount,
        o.payment_method,
        o.campaign_id,
        o.sales_employee_id,
        o.order_notes,

        c.customer_name,
        c.email_id,
        c.phone_number,
        c.city,
        c.state,
        c.country,
        c.signup_date_parsed,

year(o.order_date) as order_year,
month(o.order_date) as order_month,

case when datediff(o.order_date,c.signup_date_parsed)<0 then null
else datediff(o.order_date,c.signup_date_parsed ) 
end as customer_tenure_days,

case when datediff(o.order_date,c.signup_date_parsed) <=30 then true 
else false 
end as is_new_customer_order 

from orders o
left join deduped_customers c
on o.customer_id=c.customer_id  
)

select * from enriched 