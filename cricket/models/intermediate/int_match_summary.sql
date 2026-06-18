{{ config(
    materialized = 'table',
    schema = 'intermediate'
) }}

with matches as (

    select
        match_id,
       -- odi_match_no,
        match_name,
        series_id,
        series_name,
        match_date,
        --match_format,

        team1_id,
        team1_name,
        team2_id,
        team2_name,

        team1_runs_scored,
        team1_wickets_fell,
        

        team2_runs_scored,
        team2_wickets_fell,
        

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
players_info as (

    select
        player_id,
        player_name
    from {{ ref('stg_players_info') }}

),

final as (

    select
        m.match_id,
        m.match_name,
        m.series_id,
        m.series_name,
        m.match_date,
  

        m.team1_id,
        m.team1_name,
        m.team2_id,
        m.team2_name,

        m.team1_runs_scored,
        m.team1_wickets_fell,
     

        m.team2_runs_scored,
        m.team2_wickets_fell,
       

        m.venue_stadium,
        m.venue_city,
        m.venue_country,

        m.toss_winner,
        m.toss_winner_choice,
        m.match_winner,
        m.match_result_text,
        p.player_name as player_of_match,

        case
            when match_winner = team1_name then team1_name
            when match_winner = team2_name then team2_name
            else null
        end as winning_team,

        case
            when match_winner = team1_name then team2_name
            when match_winner = team2_name then team1_name
            else 'Tie'
        end as losing_team,

        case
            when toss_winner = match_winner then 1
            else 0
        end as toss_winner_won_match_flag,

        case
            when match_winner != toss_winner then 1
            else 0
        end as toss_lost_won_match_flag,

        case
            when lower(toss_winner_choice) in ('bat', 'bat first', 'batting') then 'Bat First'
            when lower(toss_winner_choice) in ('field', 'bowl', 'field first', 'bowling') then 'Field First'
            else 'Unknown'
        end as toss_decision_group,

        case
            when team1_runs_scored > team2_runs_scored then team1_name
            when team2_runs_scored > team1_runs_scored then team2_name
            else 'Same Runs'
        end as higher_scoring_team,

        abs(coalesce(team1_runs_scored, 0) - coalesce(team2_runs_scored, 0)) as run_difference,

        case
            when match_result_text ilike '%runs%' then 'Won By Runs'
            when match_result_text ilike '%wicket%' then 'Won By Wickets'
            when match_result_text ilike '%tie%' then 'Tie'
            when match_result_text ilike '%no result%' then 'No Result'
            else 'Other'
        end as result_type,


        from matches m
        left join players_info p
            on m.player_of_match = p.player_id

)

select *
from final