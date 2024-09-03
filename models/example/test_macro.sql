{{ config(materialized='table')}}

with source_data as (
    select film_id, rating, language_id, concat(film_id, '-', rating) as film_rating_con
    from film
)

select *
from source_data
