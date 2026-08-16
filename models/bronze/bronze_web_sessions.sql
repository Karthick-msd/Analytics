{{
  config(
    materialized = 'table',
    )
}}
select 
*,
    _metadata.file_modification_time as file_modification_time,
    _metadata.file_name as source_file_name,
    current_timestamp() as _loaded_at 

from read_files (
    '{{ var("web_sessions_path", "dbfs:/Volumes/data_mart/source/my_volume/web_sessions.csv") }}',
    format=>'csv',
    header => true,
    Schema=> '
        session_id INT,
        customer_id INT,
        session_date STRING,
        device_type STRING,
        pages_viewed INT,
        duration_seconds INT,
        campaign_id INT,
        utm_source STRING,
        raw_device_metadata STRING
    '
)