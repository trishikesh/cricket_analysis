-- makes physical table -- faster query performance & good for repeated reporting

{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with source as (     -- CTE is 'source'

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
     --   team1_extras_received,

        team2_runs_scored,
        team2_wickets_fell,
     --   team2_extras_received,

        toss_winner,
        toss_winner_choice,
        toss_decision_group,
        toss_winner_won_match_flag,

        winning_team,
        losing_team,
        result_type,
        run_difference,

        player_of_match,

        venue_stadium,
        venue_city,
        venue_country,

      

    from {{ ref('int_match_summary') }}

),

final as (

    select
        

        match_id,
        match_name,

        series_id,
        series_name,
        match_date,
        year(match_date) as match_year,

        team1_id,
        team1_name,
        team2_id,
        team2_name,

        team1_runs_scored,
        team1_wickets_fell,
        --team1_extras_received,

        team2_runs_scored,
        team2_wickets_fell,
       -- team2_extras_received,

        toss_winner,
        toss_winner_choice,
        toss_decision_group,
        toss_winner_won_match_flag,

        winning_team,
        losing_team,
        result_type,
        run_difference,

        player_of_match,

        
        venue_stadium,
        venue_city,
        venue_country,

      

    from source

)

select *
from final