{{ config(
    materialized = 'table',
    schema = 'intermediate'
) }}

with matches as (

    select
        match_id,
        odi_match_no,
        match_name,
        series_id,
        series_name,
        match_date,
        match_format,

        team1_id,
        team1_name,
        team2_id,
        team2_name,

        team1_runs_scored,
        team1_wickets_fell,
        team1_extras_received,

        team2_runs_scored,
        team2_wickets_fell,
        team2_extras_received,

        venue_stadium,
        venue_city,
        venue_country,

        toss_winner,
        toss_winner_choice,
        match_winner,
        match_result_text,
        player_of_match

    from {{ ref('stg_odi_matches_data') }}

),

final as (

    select
        match_id,
        odi_match_no,
        match_name,
        series_id,
        series_name,
        match_date,
        match_format,

        team1_id,
        team1_name,
        team2_id,
        team2_name,

        team1_runs_scored,
        team1_wickets_fell,
        team1_extras_received,

        team2_runs_scored,
        team2_wickets_fell,
        team2_extras_received,

        venue_stadium,
        venue_city,
        venue_country,

        toss_winner,
        toss_winner_choice,
        match_winner,
        match_result_text,
        player_of_match,

        concat(team1_name, ' vs ', team2_name) as match_display_name,

        concat(
            coalesce(venue_stadium, ''),
            ', ',
            coalesce(venue_city, ''),
            ', ',
            coalesce(venue_country, '')
        ) as venue_full_name,

        concat(
            coalesce(venue_stadium, 'Unknown Stadium'),
            '_',
            coalesce(venue_city, 'Unknown City'),
            '_',
            coalesce(venue_country, 'Unknown Country')
        ) as venue_key,

        case
            when match_winner = team1_name then team1_name
            when match_winner = team2_name then team2_name
            else null
        end as winning_team,

        case
            when match_winner = team1_name then team2_name
            when match_winner = team2_name then team1_name
            else null
        end as losing_team,

        case
            when toss_winner = match_winner then 1
            else 0
        end as toss_winner_won_match_flag,

        case
            when lower(toss_winner_choice) in ('bat', 'bat first', 'batting') then 'Bat First'
            when lower(toss_winner_choice) in ('field', 'bowl', 'field first', 'bowling') then 'Field First'
            else 'Unknown'
        end as toss_decision_group,

        case
            when team1_runs_scored > team2_runs_scored then team1_name
            when team2_runs_scored > team1_runs_scored then team2_name
            else null
        end as higher_scoring_team,

        abs(coalesce(team1_runs_scored, 0) - coalesce(team2_runs_scored, 0)) as run_difference,

        case
            when match_result_text ilike '%runs%' then 'Won By Runs'
            when match_result_text ilike '%wicket%' then 'Won By Wickets'
            when match_result_text ilike '%tie%' then 'Tie'
            when match_result_text ilike '%no result%' then 'No Result'
            else 'Other'
        end as result_type,

        case
            when team1_wickets_fell = 10 then 1
            else 0
        end as team1_all_out_flag,

        case
            when team2_wickets_fell = 10 then 1
            else 0
        end as team2_all_out_flag

    from matches

)

select *
from final