{{ config(materialized='table')}}

with source_data as (
    select film_id, rating, language_id
    from film
)

select *
from source_data
