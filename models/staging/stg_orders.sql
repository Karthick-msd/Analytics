{{config(

    materialized='table'
)}}

select 
order_id ,
customer_id ,
product_id ,
quantity ,

coalesce (
try_to_date(order_date,'yyyy-MM-dd'),
try_to_date(order_date, 'MM/dd/yyyy'),
try_to_date(order_date, 'dd-MM-yyyy'),
try_to_date(order_date, 'dd-MMM-yyyy'),
try_to_date(order_date,'MM-dd-yyyy')
) as order_date ,

case 
when order_status in ('NA','N/A','n/a', '-', 'null', 'na', 'none', 'unknown', '--','')
then null
else initcap(lower(order_status)) end as order_status ,

case 
when total_amount in ('NA','N/A','n/a', '-', 'null', 'na', 'none', 'unknown', '--','','NaN') 
then null
else 
round(
    try_cast(
        regexp_replace(total_amount,'[^0-9.]','') as double
    ), 2
) end as total_amount ,

case
when payment_method in ('NA','N/A','n/a', '-', 'null', 'na', 'none', 'unknown', '--','')
 then 'NOT RECORDED'

when payment_method is null 
 then 'NOT RECORDED'
else initcap(lower(payment_method)) end as payment_method ,

campaign_id  , 

sales_employee_id ,

order_notes  
from read_files (
  '/Volumes/data_mart/source/my_volume/orders.csv',
    format=> 'csv',
    header => true,
    inferSchema => false
)
