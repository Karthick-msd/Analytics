with source as (
    select * from {{ ref('bronze_hr_attendance') }}
),

deduped as (
    -- Same defensive dedup pattern as every staging model in this project:
    -- keep the LATEST bronze load per natural key, in case the watchdog
    -- uploader ever re-drops a file (it will, eventually).
    select
        *,
        row_number() over (
            partition by attendance_id
            order by _bronze_loaded_at desc
        ) as _rn
    from source
),

cleaned as (
    select
        cast(attendance_id as bigint)   as attendance_id,
        cast(employee_id as bigint)     as employee_id,
{{ parse_multi_format_date('attendance_date',['yyyy-MM-dd',
'MM-dd-yyyy','MM/dd/yyyy','dd/MM/yyyy', 
'dd-MM-yyyy','yyyy/MM/dd','MMMM d, yyyy', 'dd-MMM-yyyy'])}} as attendance_date,
        initcap(trim(status))           as attendance_status,
        cast(hours_worked as decimal(5,2)) as hours_worked,
        cast(notes as string) as notes, 
        -- Data-quality flag, not a filter. Staging's job is to EXPOSE bad data,
        -- not silently fix or hide it -- an "Absent" record with logged hours
        -- is a real-world timesheet contradiction your gold layer needs to know about.
        case
            when initcap(trim(status)) = 'Absent' and hours_worked > 0 then true
            when initcap(trim(status)) = 'Present' and hours_worked = 0 then true
            else false
        end as is_status_hours_mismatch
    from deduped
    where _rn = 1
)
select * from cleaned