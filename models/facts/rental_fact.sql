{{config(materialized='incremental', unique_key='rental_id')}}

with rental_base_1 as (
    SELECT
        *,
        EXTRACT(EPOCH from rental_date::timestamp) as rental_epoch,
        EXTRACT(EPOCH from return_date::timestamp) as return_epoch,
        EXTRACT(EPOCH from return_date::timestamp) - EXTRACT(EPOCH from rental_date::timestamp) as diff,
        (case when return_date is not null then 1 else 0 end) as is_return,
        to_char(rental_date::timestamp, 'YYYYMMDD')::integer as date_key,
        '{{ run_started_at.strftime ("%Y-%m-%d %H:%M:%S") }} '::timestamp as dbt_time
    FROM {{ source('public', 'rental') }}
),

inventory as (
    select * from {{ source('public', 'inventory')}}
),

dim_film as (
    select * from {{ ref('film_dim') }}
),
dim_store as (
    select * from {{ ref('store_dim') }}
),
dim_staff as (
    select * from {{ ref('staff_dim') }}
),
--
dim_customer as (
    select * from {{ ref('customer_dim') }}
),
--

--


rental_base_2 as (
    select
        rental_base_1.*,
        inventory.store_id,
        inventory.film_id
    from rental_base_1
    join inventory on 1=1 and inventory.inventory_id = rental_base_1.inventory_id
),
--
rental_base_3 as (
    select
        rental_base_2.*,
        (case when dim_staff.staff_id is not null then dim_staff.staff_id else -1 end) as staff_id_rental_check,
        (case when dim_customer.customer_id is not null then dim_customer.customer_id else -1 end) as customer_id_check,
        (case when dim_film.film_id is not null then dim_film.film_id else -1 end) as film_id_check,
        (case when dim_store.store_id is not null then dim_store.store_id else -1 end) as store_id_check
    from rental_base_2
    left join dim_staff on 1=1 and dim_staff.staff_id = rental_base_2.staff_id
    left join dim_customer on 1=1 and dim_customer.customer_id = rental_base_2.customer_id
    left join dim_film on 1=1 and dim_film.film_id = rental_base_2.film_id
    left join dim_store on 1=1 and dim_store.store_id = rental_base_2.store_id
)
--
--
SELECT
    rental_id,
    rental_date,
    date_key,
    inventory_id,
    staff_id_rental_check as staff_id,
    customer_id_check as customer_id,
    film_id_check as film_id,
    store_id_check as store_id,
    return_date,
    (case when return_date is not null then diff/3600 else null end) rental_hours,
    is_return,
    last_update,
    dbt_time
from rental_base_3
where 1=1
{% if is_incremental() %}
and last_update::timestamp > (select max(last_update) - INTERVAL '10 minutes' from {{this}})
{% endif %}
