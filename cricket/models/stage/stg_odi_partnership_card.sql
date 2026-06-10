-- models/stage/stg_odi_partnership_card.sql

{{ config(materialized='view') }}

select
    nullif(trim(match_id::string), '')          as match_id,
    innings::int                               as innings,
    for_wicket::int                            as for_wicket,
    nullif(trim(team::string), '')              as team,
    nullif(trim(opposition::string), '')        as opposition,

    nullif(trim(player1::string), '')           as player1,
    nullif(trim(player2::string), '')           as player2,

    player1_runs::int                          as player1_runs,
    player2_runs::int                          as player2_runs,
    player1_balls::int                         as player1_balls,
    player2_balls::int                         as player2_balls,

    partnership_runs::int                      as partnership_runs,
    partnership_balls::int                     as partnership_balls
from {{ source('staging', 'ODI_PARTNERSHIP_CARD') }}