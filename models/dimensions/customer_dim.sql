{{config(materialized='incremental', unique_key='customer_id', post_hook='insert into {{this}}(customer_id) VALUES (-1)')}}
with customer_base as (
    SELECT
        *,
        concat(customer.first_name, ' ', customer.last_name) as full_name,
--        substring(email from POSITION("@" in customer.email)+1 for char_length(customer.email)-POSITION("@" in customer.email)) as domain,
        customer.active::int as active_int,
        (case when customer.active=0 then 'no' else 'yes' end) as active_text,
        '{{ run_started_at.strftime ("%Y-%m-%d %H:%M:%S") }} '::timestamp as dbt_time

    FROM {{ source('public', 'customer') }} as customer
),

address as (
    select * from {{ source('public', 'address')}}
),

city as (
    select * from {{ source('public', 'city')}}
),

country as (
    select * from {{ source('public', 'country')}}
)


SELECT
    customer_base.customer_id,
    customer_base.store_id,
    customer_base.first_name,
    customer_base.last_name,
    customer_base.full_name,
    customer_base.email,
--    customer_base.domain,
    customer_base.active_int as active,
    customer_base.active_text,

    address.address_id,
    address.address,
    city.city_id,
    city.city,
    country.country_id,
    country.country,

    customer_base.create_date,
    customer_base.last_update,
    customer_base.dbt_time

FROM customer_base
LEFT JOIN public.address as address ON customer_base.address_id = address.address_id
LEFT JOIN public.city city ON address.city_id = city.city_id
LEFT JOIN public.country country ON city.country_id = country.country_id
WHERE 1=1
{% if is_incremental() %}
and last_update::timestamp > (select max(last_update) - INTERVAL '10 minutes' from {{this}})
{% endif %}