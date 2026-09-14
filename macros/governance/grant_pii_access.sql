-- macros/governance/grant_pii_access.sql
{% macro grant_pii_access() %}

-- GRANT SELECT ON TABLE data_mart.silver.stg_customers TO `pii_readers`;
-- ^ commented out, no account-level group exists on Free Edition

GRANT SELECT ON TABLE data_mart.silver.stg_customers TO `pii_readers`;

{% endmacro %}