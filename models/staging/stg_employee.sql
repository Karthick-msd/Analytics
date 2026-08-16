{{ config (
    materialized='table'
)}}

select employee_id as EmployeeId,

initcap(lower(employee_name)) as EmployeeName ,

case 
when department in ('NA','N/A','n/a', '-', 'null', 'na', 'none', 'unknown', '--','')
then null
else lower(department) end as Department ,

case 
when role in ('NA','N/A','n/a', '-', 'null', 'na', 'none', 'unknown', '--','')
then null
else
initcap(lower(role)) end as Role ,

coalesce (
try_to_date(hire_date,'yyyy-MM-dd'),
try_to_date(hire_date,'MM/dd/yyyy'),
try_to_date(hire_date,'dd-MM-yyyy'),
try_to_date(hire_date,'dd-MMM-yyyy'),
try_to_date(hire_date,'mm-dd-yyyy') 
) as HireDate,

manager_id as ManagerId,
email as EmailId 

from read_files (
      '/Volumes/data_mart/source/my_volume/employees.csv',
        format=> 'csv',
        header=> true, 
        inferSchema => false
)