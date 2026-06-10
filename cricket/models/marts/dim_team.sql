{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with teams as (

    select distinct
        team_id,
        team_name

    from {{ ref('int_team_innings_performance') }}

    where team_id is not null
       or team_name is not null

),

team_stats as (

    select
        team_name,

        count(distinct match_id) as total_matches_played,
        sum(win_flag) as total_wins,
        sum(loss_flag) as total_losses,
        sum(toss_win_flag) as total_toss_wins,
        sum(toss_and_match_win_flag) as total_toss_and_match_wins,

        avg(runs_scored) as avg_runs_scored,
        avg(wickets_lost) as avg_wickets_lost,
        avg(runs_conceded) as avg_runs_conceded,
        avg(wickets_taken) as avg_wickets_taken,

        max(runs_scored) as highest_team_score,
        min(nullif(runs_scored, 0)) as lowest_team_score

    from {{ ref('int_team_innings_performance') }}

    group by team_name

),

final as (

    select
        md5(coalesce(cast(t.team_id as varchar), t.team_name)) as team_key,
        md5(coalesce(t.team_name, '')) as team_key_by_name,

        t.team_id,
        t.team_name,

        coalesce(s.total_matches_played, 0) as total_matches_played,
        coalesce(s.total_wins, 0) as total_wins,
        coalesce(s.total_losses, 0) as total_losses,
        coalesce(s.total_toss_wins, 0) as total_toss_wins,
        coalesce(s.total_toss_and_match_wins, 0) as total_toss_and_match_wins,

        round(
            coalesce(s.total_wins, 0) / nullif(s.total_matches_played, 0) * 100,
            2
        ) as win_percentage,

        round(
            coalesce(s.total_toss_and_match_wins, 0) / nullif(s.total_toss_wins, 0) * 100,
            2
        ) as toss_to_match_win_percentage,

        round(s.avg_runs_scored, 2) as avg_runs_scored,
        round(s.avg_wickets_lost, 2) as avg_wickets_lost,
        round(s.avg_runs_conceded, 2) as avg_runs_conceded,
        round(s.avg_wickets_taken, 2) as avg_wickets_taken,

        s.highest_team_score,
        s.lowest_team_score

    from teams t

    left join team_stats s
        on t.team_name = s.team_name

)

select *
from final