-- models/stage/stg_odi_fow_card.sql

{{ config(materialized='view') }}

select
    nullif(trim(match_id::string), '')          as match_id,
    innings::int                               as innings,
    nullif(trim(team::string), '')              as team,
    nullif(trim(player::string), '')            as player,
    wicket::int                                as wicket_number,
    over::float                                as over_number,
    runs::int                                  as team_runs
from {{ source('staging', 'ODI_FOW_CARD') }}