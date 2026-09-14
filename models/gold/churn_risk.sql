{{
    config(
        materialized='table'
    )
}} 
select a.customer_id, 
count(a.ticket_id) as raised_tickets , b.subscription_status
from stg_support_tickets a 
join stg_subscriptions b 
on a.customer_id = b.customer_id 
group by a.customer_id , b.subscription_status
