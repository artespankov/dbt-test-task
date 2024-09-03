
SELECT
    *,
    '{{ run_started_at.strftime ("%Y-%m-%d %H:%M:%S") }}'::timestamp as dbt_time
FROM {{ source('public', 'payment') }}
