{% macro parse_null(column_name, placeholders=[
    'na', 'n/a', '-', 'null', 'none', 'unknown', '--',
    'Nan','NA','N/A','NULL'
]) %}

case
    when {{ column_name }} is null then null
    when lower(trim({{ column_name }})) in (
        {% for p in placeholders %}
            '{{ p | lower }}'
            {% if not loop.last %}, {% endif %}
        {% endfor %}
    ) then null
    else lower(trim({{ column_name }}))
end

{% endmacro %}