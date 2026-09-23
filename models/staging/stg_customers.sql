{{ config(
    materialized='incremental',
    unique_key = 'customer_id',
    incremental_strategy='merge',
    cluster_by=['customer_id','signup_date_parsed'],
    post_hook="ALTER TABLE {{ this }} ALTER COLUMN customer_id SET MASK data_mart.governance.mask_customer_id"

) }}

SELECT customer_id ,

COALESCE( 
    {{ parse_null('customer_name') }}, 

    initcap(
        
        trim(
            regexp_replace(
                split(email, '@')[0], '[._0-9]+', ' ')))
) AS customer_name,

{{parse_null('email')}} as email_id,


case when phone rlike '[n/a]+[0-9]+\\.[0-9]+E\\+[0-9]+' then null
else phone 
end as phone_number,

{{parse_null('city')}} as city, 

{{parse_null('state')}} as state, 

{{parse_null('country')}} as country, 


{{ parse_multi_format_date('signup_date',['yyyy-MM-dd',
'MM-dd-yyyy','MM/dd/yyyy','dd/MM/yyyy', 
'dd-MM-yyyy','yyyy/MM/dd','MMMM d, yyyy', 'dd-MMM-yyyy']) }} as signup_date_parsed,

customer_segment 

from {{ref ('bronze_customers')}}

{% if is_incremental() %}
where _bronze_loaded_at > (select coalesce(max(_bronze_loaded_at), '1900-01-01') from {{ this }})
{% endif %}