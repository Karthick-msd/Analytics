{% snapshot customers_snapshot %}

{{
    config(
      target_schema='silver',
      unique_key='customer_id',
      strategy='timestamp',
      updated_at='signup_date_parsed',
      invalidate_hard_deletes=True
    )
}}

select
    customer_id,
    customer_name,
    email_id,
    phone_number,
    city,
    state,
    country,
    signup_date_parsed
from {{ ref('stg_customers') }}

{% endsnapshot %} 