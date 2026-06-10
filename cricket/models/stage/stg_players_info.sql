-- models/stage/stg_players_info.sql

{{ config(materialized='view') }}

select
    nullif(trim(player_id::string), '')         as player_id,
    nullif(trim(player_object_id::string), '')  as player_object_id,
    nullif(trim(player_name::string), '')       as player_name,
    try_to_date(dob::string)                    as dob,
    try_to_date(dod::string)                    as dod,
    lower(nullif(trim(gender::string), ''))     as gender,
    nullif(trim(batting_style::string), '')     as batting_style,
    nullif(trim(bowling_style::string), '')     as bowling_style,
    nullif(trim(country_id::string), '')        as country_id,
from {{ source('staging', 'PLAYERS_INFO') }}