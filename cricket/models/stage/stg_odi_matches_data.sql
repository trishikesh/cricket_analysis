-- models/stage/stg_odi_matches_data.sql

{{ config(materialized='view') }}

select
    odi_match_no::int                          as odi_match_no,
    nullif(trim(match_id::string), '')          as match_id,
    nullif(trim(match_name::string), '')        as match_name,
    nullif(trim(series_id::string), '')         as series_id,
    nullif(trim(series_name::string), '')       as series_name,
    try_to_date(match_date::string)             as match_date,
    upper(nullif(trim(match_format::string), '')) as match_format,

    nullif(trim(team1_id::string), '')          as team1_id,
    nullif(trim(team1_name::string), '')        as team1_name,
    nullif(trim(team1_captain::string), '')     as team1_captain,
    team1_runs_scored::int                     as team1_runs_scored,
    team1_wickets_fell::int                    as team1_wickets_fell,
    team1_extras_rec::int                      as team1_extras_received,

    nullif(trim(team2_id::string), '')          as team2_id,
    nullif(trim(team2_name::string), '')        as team2_name,
    nullif(trim(team2_captain::string), '')     as team2_captain,
    team2_runs_scored::int                     as team2_runs_scored,
    team2_wickets_fell::int                    as team2_wickets_fell,
    team2_extras_rec::int                      as team2_extras_received,

    nullif(trim(match_venue_stadium::string), '') as venue_stadium,
    nullif(trim(match_venue_city::string), '')    as venue_city,
    nullif(trim(match_venue_country::string), '') as venue_country,

    nullif(trim(umpire_1::string), '')          as umpire_1,
    nullif(trim(umpire_2::string), '')          as umpire_2,
    nullif(trim(match_referee::string), '')     as match_referee,

    nullif(trim(toss_winner::string), '')       as toss_winner,
    lower(nullif(trim(toss_winner_choice::string), '')) as toss_winner_choice,

    nullif(trim(match_winner::string), '')      as match_winner,
    nullif(trim(match_result_text::string), '') as match_result_text,
    nullif(trim(mom_player::string), '')        as player_of_match,

    nullif(trim(team1_playing_11::string), '')  as team1_playing_11,
    nullif(trim(team2_playing_11::string), '')  as team2_playing_11,
    nullif(trim(debut_players::string), '')     as debut_players
from {{ source('staging', 'ODI_MATCHES_DATA') }}