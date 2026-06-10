{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with source as (

    select
        match_id,
        odi_match_no,
        match_name,
        match_display_name,
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

        toss_winner,
        toss_winner_choice,
        toss_decision_group,
        toss_winner_won_match_flag,

        match_winner,
        winning_team,
        losing_team,
        match_result_text,
        result_type,
        run_difference,

        player_of_match,

        venue_key,
        venue_full_name,
        venue_stadium,
        venue_city,
        venue_country,

        team1_all_out_flag,
        team2_all_out_flag

    from {{ ref('int_match_summary') }}

),

final as (

    select
        md5(cast(match_id as varchar)) as match_key,

        match_id,
        odi_match_no,
        match_name,
        match_display_name,

        series_id,
        series_name,
        match_date,
        year(match_date) as match_year,
        month(match_date) as match_month,
        quarter(match_date) as match_quarter,
        dayname(match_date) as match_day_name,

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

        toss_winner,
        toss_winner_choice,
        toss_decision_group,
        toss_winner_won_match_flag,

        match_winner,
        winning_team,
        losing_team,
        match_result_text,
        result_type,
        run_difference,

        player_of_match,

        
        venue_full_name,
        venue_stadium,
        venue_city,
        venue_country,

        team1_all_out_flag,
        team2_all_out_flag

    from source

)

select *
from final