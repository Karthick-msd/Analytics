
-- Enrichment pattern: fact (hr_attendance) joined to dimension (employee),
-- rolled up to one row per employee. 
with attendance as (

    select * from {{ ref('stg_hr_attendance') }}

),

employee as (

    select * from {{ ref('stg_employee') }}

),

attendance_summary as (
    select
        employee_id,
        count(*)                                                   as total_days_logged,
        sum(case when attendance_status = 'Present' then 1 else 0 end) as days_present,
        sum(case when attendance_status = 'Absent'  then 1 else 0 end) as days_absent,
        sum(case when attendance_status = 'Leave'   then 1 else 0 end) as days_on_leave,
        sum(hours_worked)                                          as total_hours_worked,
        sum(case when is_status_hours_mismatch then 1 else 0 end)  as mismatch_count
    from attendance
    group by employee_id
),
final as (
select
    e.employee_id,
    e.employee_name,
    e.department,
    e.role,
    e.hire_date,
    e.manager_id,
    e.email,
    s.total_days_logged,
    s.days_present,
    s.days_absent,
    s.days_on_leave,
    s.total_hours_worked,
    s.mismatch_count,
    s.days_present / nullif(s.total_days_logged, 0) as attendance_rate

from employee e
left join attendance_summary s
    on e.employee_id = s.employee_id
)
select * from final