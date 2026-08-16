{% macro mask_customer_id() %}

CREATE SCHEMA IF NOT EXISTS data_mart.governance;

CREATE OR REPLACE FUNCTION data_mart.governance.mask_customer_id(customer_id STRING)
RETURNS STRING
COMMENT 'Masks customer_id when user belongs to pii_readers group'
RETURN CASE
  WHEN is_account_group_member('pii_readers') THEN customer_id
  ELSE '*****'
END;

{% endmacro %}