{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with batting_players as (

    select distinct
        batsman as player_name,
        team as team_name,
        'Batter' as player_source_role

    from {{ ref('int_batting_performance') }}

    where batsman is not null

),

bowling_players as (

    select distinct
        bowler_id as player_name,
        team as team_name,
        'Bowler' as player_source_role

    from {{ ref('int_bowling_performance') }}

    where bowler_id is not null

),

unioned as (

    select *
    from batting_players

    union all

    select *
    from bowling_players

),

player_base as (

    select
        player_name,
        team_name,

        max(case when player_source_role = 'Batter' then 1 else 0 end) as has_batting_record,
        max(case when player_source_role = 'Bowler' then 1 else 0 end) as has_bowling_record

    from unioned

    group by
        player_name,
        team_name

),

batting_stats as (

    select
        batsman as player_name,
        team as team_name,

        count(distinct match_id) as batting_matches,
        sum(runs) as total_runs,
        sum(balls) as total_balls_faced,
        sum(fours) as total_fours,
        sum(sixes) as total_sixes,
        sum(hundred_flag) as total_hundreds,
        sum(fifty_flag) as total_fifties,
        sum(duck_flag) as total_ducks,
        max(runs) as highest_score,

        sum(case when is_out = 1 then 1 else 0 end) as total_dismissals

    from {{ ref('int_batting_performance') }}

    group by
        batsman,
        team

),

bowling_stats as (

    select
        bowler_id as player_name,
        team as team_name,

        count(distinct match_id) as bowling_matches,
        sum(wickets) as total_wickets,
        sum(runs_conceded) as total_runs_conceded,
        sum(balls) as total_balls_bowled,
        sum(dots) as total_dot_balls,
        sum(maidens) as total_maidens,
        sum(five_wicket_haul_flag) as total_five_wicket_hauls,
        max(wickets) as best_wickets_in_match

    from {{ ref('int_bowling_performance') }}

    group by
        bowler_id,
        team

),

final as (

    select
        md5(coalesce(pb.player_name, '') || '_' || coalesce(pb.team_name, '')) as player_key,

        pb.player_name,
        pb.team_name,

        case
            when pb.has_batting_record = 1 and pb.has_bowling_record = 1 then 'All-rounder'
            when pb.has_batting_record = 1 then 'Batter'
            when pb.has_bowling_record = 1 then 'Bowler'
            else 'Unknown'
        end as player_role_group,

        pb.has_batting_record,
        pb.has_bowling_record,

        coalesce(bs.batting_matches, 0) as batting_matches,
        coalesce(bs.total_runs, 0) as total_runs,
        coalesce(bs.total_balls_faced, 0) as total_balls_faced,
        coalesce(bs.total_fours, 0) as total_fours,
        coalesce(bs.total_sixes, 0) as total_sixes,
        coalesce(bs.total_hundreds, 0) as total_hundreds,
        coalesce(bs.total_fifties, 0) as total_fifties,
        coalesce(bs.total_ducks, 0) as total_ducks,
        bs.highest_score,

        round(
            coalesce(bs.total_runs, 0) / nullif(bs.total_dismissals, 0),
            2
        ) as batting_average,

        round(
            coalesce(bs.total_runs, 0) / nullif(bs.total_balls_faced, 0) * 100,
            2
        ) as career_strike_rate,

        coalesce(bws.bowling_matches, 0) as bowling_matches,
        coalesce(bws.total_wickets, 0) as total_wickets,
        coalesce(bws.total_runs_conceded, 0) as total_runs_conceded,
        coalesce(bws.total_balls_bowled, 0) as total_balls_bowled,
        coalesce(bws.total_dot_balls, 0) as total_dot_balls,
        coalesce(bws.total_maidens, 0) as total_maidens,
        coalesce(bws.total_five_wicket_hauls, 0) as total_five_wicket_hauls,
        bws.best_wickets_in_match,

        round(
            coalesce(bws.total_runs_conceded, 0) / nullif(bws.total_wickets, 0),
            2
        ) as bowling_average,

        round(
            coalesce(bws.total_runs_conceded, 0) / nullif(bws.total_balls_bowled, 0) * 6,
            2
        ) as career_economy_rate,

        round(
            coalesce(bws.total_balls_bowled, 0) / nullif(bws.total_wickets, 0),
            2
        ) as bowling_strike_rate

    from player_base pb

    left join batting_stats bs
        on pb.player_name = bs.player_name
        and pb.team_name = bs.team_name

    left join bowling_stats bws
        on pb.player_name = bws.player_name
        and pb.team_name = bws.team_name

)

select *
from final