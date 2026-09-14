{{ config (
    materialized='table'
)}}

select employee_id ,

initcap(lower(employee_name)) as employee_name ,

case 
when department in ('NA','N/A','n/a', '-', 'null', 'na', 'none', 'unknown', '--','')
then null
else lower(department) end as department ,

case 
when role in ('NA','N/A','n/a', '-', 'null', 'na', 'none', 'unknown', '--','')
then null
else
initcap(lower(role)) end as role ,

coalesce (
try_to_date(hire_date,'yyyy-MM-dd'),
try_to_date(hire_date,'MM/dd/yyyy'),
try_to_date(hire_date,'dd-MM-yyyy'),
try_to_date(hire_date,'dd-MMM-yyyy'),
try_to_date(hire_date,'mm-dd-yyyy') 
) as hire_date,

manager_id ,
email 

from {{ ref('bronze_employee')}}