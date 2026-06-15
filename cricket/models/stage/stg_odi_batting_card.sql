{{ config(materialized='view') }}   --jinja syntax - to build database view (view cuz need no duplication - only light cleaning - raw is untouched & when view is quired it reflects changes of raw)



select   --run the below columns from source
    nullif(trim(match_id::string), '')          as match_id,   --casting match_id as string - trimming to remove whitespace for proper join/comparision - nullif(A,'') will chekc if a is '' -if yes then return null else A
    innings::int                               as innings,
    nullif(trim(team::string), '')              as team,
    nullif(trim(batsman::string), '')           as batsman,
    runs::int                                  as runs,
    balls::int                                 as balls,
    fours::int                                 as fours,
    sixes::int                                 as sixes,
    strikerate::float                          as strike_rate,  --naming standardization
    isout::boolean                             as is_out,
    nullif(trim(wickettype::string), '')        as wicket_type,
    nullif(trim(fielders::string), '')          as fielders,
    nullif(trim(bowler::string), '')            as bowler
from {{ source('staging', 'ODI_BATTING_CARD') }}

-- soucre is define in stage.yml - raw data is to be read from here - group = staging & table = odi_batting_card

