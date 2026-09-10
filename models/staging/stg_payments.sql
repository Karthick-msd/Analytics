

with source as (

    select * from {{ ref('bronze_payments') }}

),

deduped as (
    select
        *,
        row_number() over (
            partition by payment_id
            order by _bronze_loaded_at desc
        ) as _rn
    from source
),

cleaned as (
    select
       {{ parse_null('payment_id')  }} as payment_id,

      {{  parse_null('order_id')  }} as order_id,

{{ parse_multi_format_date('payment_date',['yyyy-MM-dd',
'MM-dd-yyyy','MM/dd/yyyy','dd/MM/yyyy', 
'dd-MM-yyyy','yyyy/MM/dd','MMMM d, yyyy', 'dd-MMM-yyyy']) }} as payment_date,




regexp_replace({{ parse_null ('amount_paid')  }}, '[^0-9.-]','') as amount_paid, 

     {{ parse_null ( 'payment_status' ) }}  ,
      initcap(trim(payment_status))  as payment_status,

      {{ parse_null('payment_method')}} , 
                initcap(trim(payment_method))  as payment_method



    from deduped
    where _rn = 1
),

result as (

    select payment_id, order_id, 
    payment_date, amount_paid, payment_status, payment_method
    from cleaned 
)
select * from result
where payment_id=925