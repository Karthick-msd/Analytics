{{
  config(
    materialized = 'table',
    cluster_by=['customer_id','parsed_session_date']
    )
}}

with source as (
select * from {{ ref ('bronze_web_sessions')}}

),

parsed as (
    SELECT
        *,
        from_json(
            raw_device_metadata,
            'browser STRING, os STRING, referrer STRING, ab_test_group STRING'
        ) AS device_metadata
    FROM source 
)
select session_id,
customer_id, 
{{ parse_multi_format_date('session_date',['yyyy-MM-dd',
'MM-dd-yyyy','MM/dd/yyyy','dd/MM/yyyy', 
'dd-MM-yyyy','yyyy/MM/dd']) }} as parsed_session_date,

{{parse_null('device_type') }} as device_type,
pages_viewed, 
duration_seconds, 
{{parse_null ('campaign_id') }} as campaign_id, 
{{ parse_null('utm_source') }} as utm_source , 

    device_metadata.browser        AS browser,
    device_metadata.os             AS os,
    device_metadata.referrer       AS referrer,
    device_metadata.ab_test_group  AS ab_test_group
from parsed 

