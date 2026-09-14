{{
    config(
        materialized = 'table'
    )
}}

with base as (
    select
        attendance_id,
        employee_id,
        attendance_date,
        lag(attendance_date) over (
            partition by employee_id order by attendance_date
        ) as prev_date
    from stg_hr_attendance
),

flagged as (
    -- Layer 2: is THIS row the start of a new streak?
    select
        *,
        case
            when prev_date is null then 1                    -- first record ever for this employee
            when datediff(attendance_date, prev_date) >= 2 then 1  -- gap of 2+ days = new streak
            else 0
        end as is_new_streak
    from base
),

grouped as (
    -- Layer 3a: running total of "new streak" flags = a stable streak ID
    select
        *,
        sum(is_new_streak) over (
            partition by employee_id order by attendance_date
        ) as streak_id
    from flagged
),

agg as (
    -- Layer 3b: collapse each streak to one row
    select
        employee_id,
        streak_id, 
        min(attendance_date) as start_date,
        max(attendance_date) as end_date,
        count(*) as duration
    from grouped
    group by employee_id, streak_id
),

ranked as (
    -- Layer 4: rank streaks (global top 3 — see note below)
    select
        *,
        rank() over (order by duration desc) as rnk
    from agg
)

select a.employee_id, a.start_date, a.end_date, 
a.duration, a.rnk , b.department
from ranked a 
join stg_employee b 
on a.employee_id= b.employee_id 
where rnk <= 5
order by duration desc
