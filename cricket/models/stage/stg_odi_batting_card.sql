-- models/stage/stg_odi_batting_card.sql

{{ config(materialized='view') }}

select
    nullif(trim(match_id::string), '')          as match_id,
    innings::int                               as innings,
    nullif(trim(team::string), '')              as team,
    nullif(trim(batsman::string), '')           as batsman,
    runs::int                                  as runs,
    balls::int                                 as balls,
    fours::int                                 as fours,
    sixes::int                                 as sixes,
    strikerate::float                          as strike_rate,
    isout::boolean                             as is_out,
    nullif(trim(wickettype::string), '')        as wicket_type,
    nullif(trim(fielders::string), '')          as fielders,
    nullif(trim(bowler::string), '')            as bowler
from {{ source('staging', 'ODI_BATTING_CARD') }}