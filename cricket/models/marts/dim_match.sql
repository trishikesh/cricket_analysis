{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with source as (

    select
        match_id,
        match_name,
        series_id,
        series_name,
        match_date,

        team1_id,
        team1_name,
        team2_id,
        team2_name,

        team1_runs_scored,
        team1_wickets_fell,

        team2_runs_scored,
        team2_wickets_fell,

        toss_winner,
        toss_winner_choice,
        toss_decision_group,
        toss_winner_won_match_flag,
        toss_lost_won_match_flag,

        winning_team,
        losing_team,
        result_type,
        run_difference,

        player_of_match,

        venue_stadium,
        venue_city,
        venue_country

    from {{ ref('int_match_summary') }}

),

final as (

    select
        match_id,
        max(match_name) as match_name,

        max(series_id) as series_id,
        max(series_name) as series_name,
        max(match_date) as match_date,
        year(max(match_date)) as match_year,

        max(team1_id) as team1_id,
        max(team1_name) as team1_name,
        max(team2_id) as team2_id,
        max(team2_name) as team2_name,

        max(team1_runs_scored) as team1_runs_scored,
        max(team1_wickets_fell) as team1_wickets_fell,

        max(team2_runs_scored) as team2_runs_scored,
        max(team2_wickets_fell) as team2_wickets_fell,

        max(toss_winner) as toss_winner,
        max(toss_winner_choice) as toss_winner_choice,
        max(toss_decision_group) as toss_decision_group,
        max(toss_winner_won_match_flag) as toss_winner_won_match_flag,
        max(toss_lost_won_match_flag) as toss_lost_won_match_flag,

        max(winning_team) as winning_team,
        max(losing_team) as losing_team,
        max(result_type) as result_type,
        max(run_difference) as run_difference,

        max(player_of_match) as player_of_match,

        max(venue_stadium) as venue_stadium,
        max(venue_city) as venue_city,
        max(venue_country) as venue_country,

        md5(
            coalesce(upper(trim(max(venue_stadium))), '')
            || '|'
            || coalesce(upper(trim(max(venue_city))), '')
            || '|'
            || coalesce(upper(trim(max(venue_country))), '')
        ) as venue_key

    from source

    group by match_id

)

select *
from final