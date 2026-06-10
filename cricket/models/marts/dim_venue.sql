{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with venue_base as (

    select distinct
        venue_key,
        venue_full_name,
        venue_stadium,
        venue_city,
        venue_country

    from {{ ref('int_match_summary') }}

    where venue_key is not null

),

venue_stats as (

    select
        venue_key,

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

    group by venue_key

),

final as (

    select
        md5(coalesce(v.venue_key, '')) as venue_key_hash,

        v.venue_key,
        v.venue_full_name,
        v.venue_stadium,
        v.venue_city,
        v.venue_country,

        coalesce(s.total_matches_hosted, 0) as total_matches_hosted,
        round(s.avg_total_match_runs, 2) as avg_total_match_runs,
        round(s.avg_team1_score, 2) as avg_team1_score,
        round(s.avg_team2_score, 2) as avg_team2_score,
        s.highest_innings_score,

        coalesce(s.matches_won_by_runs, 0) as matches_won_by_runs,
        coalesce(s.matches_won_by_wickets, 0) as matches_won_by_wickets,

        round(
            coalesce(s.matches_won_by_runs, 0) / nullif(s.total_matches_hosted, 0) * 100,
            2
        ) as bat_first_win_percentage,

        round(
            coalesce(s.matches_won_by_wickets, 0) / nullif(s.total_matches_hosted, 0) * 100,
            2
        ) as chasing_win_percentage,

        round(
            coalesce(s.toss_winner_match_wins, 0) / nullif(s.total_matches_hosted, 0) * 100,
            2
        ) as toss_winner_win_percentage

    from venue_base v

    left join venue_stats s
        on v.venue_key = s.venue_key

)

select *
from final