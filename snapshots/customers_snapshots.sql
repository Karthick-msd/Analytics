{# 
previuosly i had updated_at='signup_date_parsed'
  updated_at='signup_date_parsed' would break SCD2 silently — 
  signup_date never changes on existing rows, so real updates 
  (email, phone, city) would never be detected as changed.
  Switched to strategy='check' with explicit check_cols because 
  the source has no reliable "last modified" column.
  but this is not the effient way of doing it. 
#}

{% snapshot customers_snapshot %}

{{
    config(
      target_schema='silver',
      unique_key='customer_id',
      strategy='check', 
      check_cols=['customer_name', 'email_id', 'phone_number', 'city', 'state', 'country'],
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