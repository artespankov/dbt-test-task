{{ config(materialized='table')}}


select *
    from {{ ref('dim_film') }}
    where replacement_cost > {{var('threshold')}}

