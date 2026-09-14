{{
  config(
    materialized = 'table',
    cluster_by=['customer_id','parsed_created_date']
    )
}}

select ticket_id,  
customer_id, 
order_id, 

{{ parse_multi_format_date('created_date',['yyyy-MM-dd',
'MM-dd-yyyy','MM/dd/yyyy','dd/MM/yyyy', 
'dd-MM-yyyy','yyyy/MM/dd']) }} as created_date, 

{{parse_null('category')}} as category, 
{{parse_null('priority')}} as priority,
{{parse_null('status')}} as status ,
{{parse_null('resolution_notes')}} as resolution_notes 

from {{ref('bronze_support_tickets')}}
