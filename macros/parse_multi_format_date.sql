{% macro parse_multi_format_date(column_name, formats) %}
coalesce(
    {% for fmt in formats %}
    try_to_date({{ column_name }}, '{{ fmt }}'){% if not loop.last %},{% endif %}
    {% endfor %}
)
{% endmacro %}

