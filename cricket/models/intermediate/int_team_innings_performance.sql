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

        team1_id,
        team1_name,
        team1_runs_scored,
        team1_wickets_fell,
        team1_extras_received,

        team2_id,
        team2_name,
        team2_runs_scored,
        team2_wickets_fell,
        team2_extras_received,

        venue_key,
        venue_stadium,
        venue_city,
        venue_country,

        toss_winner,
        toss_winner_choice,
        match_winner,
        match_result_text,
        result_type,
        run_difference

    from {{ ref('int_match_summary') }}

),

team1_rows as (

    select
        match_id,
        odi_match_no,
        match_name,
        series_id,
        series_name,
        match_date,

        1 as team_position,
        team1_id as team_id,
        team1_name as team_name,
        team2_id as opposition_id,
        team2_name as opposition_name,

        team1_runs_scored as runs_scored,
        team1_wickets_fell as wickets_lost,
        team1_extras_received as extras_received,

        team2_runs_scored as runs_conceded,
        team2_wickets_fell as wickets_taken,
        team2_extras_received as extras_conceded,

        venue_key,
        venue_stadium,
        venue_city,
        venue_country,

        toss_winner,
        toss_winner_choice,
        match_winner,
        match_result_text,
        result_type,
        run_difference

    from matches

),

team2_rows as (

    select
        match_id,
        odi_match_no,
        match_name,
        series_id,
        series_name,
        match_date,

        2 as team_position,
        team2_id as team_id,
        team2_name as team_name,
        team1_id as opposition_id,
        team1_name as opposition_name,

        team2_runs_scored as runs_scored,
        team2_wickets_fell as wickets_lost,
        team2_extras_received as extras_received,

        team1_runs_scored as runs_conceded,
        team1_wickets_fell as wickets_taken,
        team1_extras_received as extras_conceded,

        venue_key,
        venue_stadium,
        venue_city,
        venue_country,

        toss_winner,
        toss_winner_choice,
        match_winner,
        match_result_text,
        result_type,
        run_difference

    from matches

),

unioned as (

    select *
    from team1_rows

    union all

    select *
    from team2_rows

),

final as (

    select
        match_id,
        odi_match_no,
        match_name,
        series_id,
        series_name,
        match_date,

        team_position,
        team_id,
        team_name,
        opposition_id,
        opposition_name,

        runs_scored,
        wickets_lost,
        extras_received,

        runs_conceded,
        wickets_taken,
        extras_conceded,

        venue_key,
        venue_stadium,
        venue_city,
        venue_country,

        toss_winner,
        toss_winner_choice,
        match_winner,
        match_result_text,
        result_type,
        run_difference,

        concat(match_id, '_', team_name) as team_match_key,

        case
            when team_name = match_winner then 1
            else 0
        end as win_flag,

        case
            when team_name <> match_winner and match_winner is not null then 1
            else 0
        end as loss_flag,

        case
            when team_name = toss_winner then 1
            else 0
        end as toss_win_flag,

        case
            when team_name = toss_winner and team_name = match_winner then 1
            else 0
        end as toss_and_match_win_flag,

        case
            when wickets_lost = 10 then 1
            else 0
        end as all_out_flag,

        case
            when runs_scored >= 350 then '350+'
            when runs_scored >= 300 then '300-349'
            when runs_scored >= 250 then '250-299'
            when runs_scored >= 200 then '200-249'
            when runs_scored >= 150 then '150-199'
            when runs_scored > 0 then 'Below 150'
            else 'Unknown'
        end as score_bucket,

        case
            when wickets_lost <= 3 then 'Strong Batting'
            when wickets_lost <= 6 then 'Average Batting'
            when wickets_lost <= 9 then 'Weak Batting'
            when wickets_lost = 10 then 'All Out'
            else 'Unknown'
        end as batting_stability_bucket,

        case
            when runs_scored > runs_conceded then 'Outscored Opposition'
            when runs_scored < runs_conceded then 'Scored Less Than Opposition'
            else 'Equal Score'
        end as scoring_result,

        runs_scored - runs_conceded as team_run_margin

    from unioned

)

select *
from final