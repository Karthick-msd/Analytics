{{
    config (
    materialized ='table',
    file_format='delta'
    )
}}

select *
 from read_files (

'{{ var("employee_path") }}',
    format => 'csv',
    header => true,
    inferSchema => true

)