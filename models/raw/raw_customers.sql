{{ config(materialized='table') }}

SELECT *,
_metadata.file_path              as _source_file_path,
_metadata.file_modification_time as _file_modified_at
FROM read_files(
   '{{ var("customers_path","dbfs:/Volumes/data_mart/source/my_volume/") }}',

    format => 'csv',
    header => true,
    inferSchema => true,
    pathGlobFilter => 'customer*.csv'

) 

