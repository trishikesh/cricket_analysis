{{ config(
    materialized = 'table',
    schema = 'intermediate'
) }}

with base as (

    select
        player_id,
        player_object_id,
        player_name,
        dob,
        gender,
        batting_style,
        bowling_style,
        country_id
    from {{ ref('stg_players_info') }}

),

player_id_map as (

    select
        player_id as player_key,
        player_id,
        player_object_id,
        player_name,
        dob,
        gender,
        batting_style,
        bowling_style,
        country_id
    from base
    where player_id is not null

),

player_object_id_map as (

    select
        player_object_id as player_key,
        player_id,
        player_object_id,
        player_name,
        dob,
        gender,
        batting_style,
        bowling_style,
        country_id
    from base
    where player_object_id is not null

),

final as (

    select * from player_id_map
    union
    select * from player_object_id_map

)

select *
from final