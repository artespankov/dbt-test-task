{{ config(materialized='incremental', unique_key='film_id', post_hook='insert into {{this}}(film_id) VALUES (-1)') }}
---
with base_film as (
    SELECT
    *,
    (case
      when length <= 75 then 'short'
      when (length > 75 and length <= 120) then 'medium'
      when length > 120 then 'long'
      else 'na'
      end
    ) as length_text,
    COALESCE(original_language_id, 0) as original_language_default_zero,
    case when POSITION('Trailers' in special_features::varchar) > 0 then 1 else 0 end has_trailers,
    case when POSITION('Commentaries' in special_features::varchar) > 0 then 1 else 0 end has_commentaries,
    case when POSITION('Deleted Scenes' in special_features::varchar) > 0 then 1 else 0 end has_deleted_scenes,
    case when POSITION('Behind the Scenes' in special_features::varchar) > 0 then 1 else 0 end has_behind_scenes,
    '{{ run_started_at.strftime ("%Y-%m-%d %H:%M:%S") }} '::timestamp as dbt_time
    FROM {{ source('public', 'film') }}
),

film_category as (
    select * from {{ source('public', 'film_category')}}
),

category as (
    select * from {{ source('public', 'category')}}
),

language as (
    select * from {{ source('public', 'language')}}
),


stg_film as (
    SELECT
        base_film.*,
        category.category_id,
        category.name as category_name,
        language.name as language_name
        from base_film
        LEFT JOIN film_category ON 1=1 AND film_category.film_id=base_film.film_id
        LEFT JOIN category ON 1=1 AND film_category.category_id=category.category_id
        LEFT JOIN language ON 1=1 AND language.language_id=base_film.language_id
)

SELECT
    film_id,
    length_text,
    has_trailers,
    has_commentaries,
    has_deleted_scenes,
    has_behind_scenes,
    category_id,
    category_name,
    language_id,
    language_name,
    original_language_default_zero,
    dbt_time
    from stg_film
    WHERE 1=1
{% if is_incremental() %}
and last_update::timestamp > (select max(last_update) - INTERVAL '10 minutes' from {{this}})
{% endif %}