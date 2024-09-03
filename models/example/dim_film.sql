{{ config(materialized='table', alias='just_for_test', schema='art')}}
--{{ config(materialized='ephemeral')}}

with film_dataset as (
    select film_id, rating, language_id, replacement_cost
    from film
)

select *
from film_dataset
