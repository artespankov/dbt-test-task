{{config(post_hook='insert into {{this}}(staff_id) VALUES (-1)')}}
with staff_base as (
    SELECT
        *,
        staff.active::int as active_int,
        (case when staff.active::int=0 then 'no' else 'yes' end) as active_text,
        '{{ run_started_at.strftime ("%Y-%m-%d %H:%M:%S") }} '::timestamp as dbt_time

    FROM {{ source('public', 'staff') }} as staff
)

SELECT
    staff_base.staff_id,
    staff_base.first_name,
    staff_base.last_name,
    staff_base.email,
    staff_base.active_int as active,
    staff_base.active_text,
    staff_base.last_update
FROM staff_base
