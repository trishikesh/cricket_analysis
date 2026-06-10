-- models/stage/stg_odi_bowling_card.sql

{{ config(materialized='view') }}

select
    nullif(trim(match_id::string), '')          as match_id,
    innings::int                               as innings,
    nullif(trim(team::string), '')              as team,
    nullif(trim(opposition::string), '')        as opposition,
    nullif(trim(bowler_id::string), '')         as bowler_id,
    overs::float                               as overs,
    balls::int                                 as balls,
    maidens::int                               as maidens,
    conceded::int                              as runs_conceded,
    wickets::int                               as wickets,
    economy::float                             as economy,
    dots::int                                  as dots,
    fours::int                                 as fours,
    sixes::int                                 as sixes,
    wides::int                                 as wides,
    noballs::int                               as no_balls
from {{ source('staging', 'ODI_BOWLING_CARD') }}