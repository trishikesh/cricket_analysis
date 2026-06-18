{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with venue_base as (

    select
        venue_stadium,
        venue_city,
        venue_country,

        count(distinct match_id) as total_matches_hosted,

        avg(
            coalesce(team1_runs_scored, 0) + coalesce(team2_runs_scored, 0)
        ) as avg_total_match_runs,

        avg(team1_runs_scored) as avg_team1_score,
        avg(team2_runs_scored) as avg_team2_score,

        max(greatest(
            coalesce(team1_runs_scored, 0),
            coalesce(team2_runs_scored, 0)
        )) as highest_innings_score,

        sum(case when result_type = 'Won By Runs' then 1 else 0 end) as matches_won_by_runs,
        sum(case when result_type = 'Won By Wickets' then 1 else 0 end) as matches_won_by_wickets,

        sum(case when toss_winner_won_match_flag = 1 then 1 else 0 end) as toss_winner_match_wins

    from {{ ref('int_match_summary') }}

    where venue_city is not null
       or venue_country is not null
       or venue_stadium is not null

    group by
        venue_stadium,
        venue_city,
        venue_country

),

final as (

    select
        md5(
            coalesce(upper(trim(venue_stadium)), '')
            || '|'
            || coalesce(upper(trim(venue_city)), '')
            || '|'
            || coalesce(upper(trim(venue_country)), '')
        ) as venue_key,

        venue_stadium,
        venue_city,
        venue_country,

        coalesce(total_matches_hosted, 0) as total_matches_hosted,
        round(avg_total_match_runs, 2) as avg_total_match_runs,
        round(avg_team1_score, 2) as avg_team1_score,
        round(avg_team2_score, 2) as avg_team2_score,
        highest_innings_score,

        coalesce(matches_won_by_runs, 0) as matches_won_by_runs,
        coalesce(matches_won_by_wickets, 0) as matches_won_by_wickets,

        round(
            coalesce(matches_won_by_runs, 0) / nullif(total_matches_hosted, 0) * 100,
            2
        ) as bat_first_win_percentage,

        round(
            coalesce(matches_won_by_wickets, 0) / nullif(total_matches_hosted, 0) * 100,
            2
        ) as chasing_win_percentage,

        round(
            coalesce(toss_winner_match_wins, 0) / nullif(total_matches_hosted, 0) * 100,
            2
        ) as toss_winner_win_percentage

    from venue_base

)

select *
from final