{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with batting_players as (

    select distinct
        batsman_id as player_id,
        batsman_name as player_name,
        'Batter' as player_source_role
    from {{ ref('int_batting_performance') }}
    where batsman_id is not null

),

bowling_players as (

    select distinct
        bowler_id as player_id,
        bowler_name as player_name,
        'Bowler' as player_source_role
    from {{ ref('int_bowling_performance') }}
    where bowler_id is not null

),

unioned as (

    select * from batting_players
    union all
    select * from bowling_players

),

player_base as (

    select
        player_id,
        max(player_name) as player_name,

        max(case when player_source_role = 'Batter' then 1 else 0 end) as has_batting_record,
        max(case when player_source_role = 'Bowler' then 1 else 0 end) as has_bowling_record

    from unioned
    group by player_id

),

batting_stats as (

    select
        batsman_id as player_id,

        count(distinct match_id) as batting_matches,
        sum(coalesce(runs, 0)) as total_runs,
        sum(coalesce(balls, 0)) as total_balls_faced,
        sum(coalesce(fours, 0)) as total_fours,
        sum(coalesce(sixes, 0)) as total_sixes,
        sum(coalesce(hundred_flag, 0)) as total_hundreds,
        sum(coalesce(fifty_flag, 0)) as total_fifties,
        sum(coalesce(duck_flag, 0)) as total_ducks,
        max(coalesce(runs, 0)) as highest_score,
        sum(case when is_out = 1 then 1 else 0 end) as total_dismissals

    from {{ ref('int_batting_performance') }}
    where batsman_id is not null

    group by batsman_id

),

bowling_stats as (

    select
        bowler_id as player_id,

        count(distinct match_id) as bowling_matches,
        sum(coalesce(wickets, 0)) as total_wickets,
        sum(coalesce(runs_conceded, 0)) as total_runs_conceded,
        sum(coalesce(balls, 0)) as total_balls_bowled,
        sum(coalesce(dots, 0)) as total_dot_balls,
        sum(coalesce(maidens, 0)) as total_maidens,
        sum(coalesce(five_wicket_haul_flag, 0)) as total_five_wicket_hauls,
        max(coalesce(wickets, 0)) as best_wickets_in_match

    from {{ ref('int_bowling_performance') }}
    where bowler_id is not null

    group by bowler_id

),
player_stats as (

    select
        pb.player_id,
        pb.player_name,

        bs.batting_matches,
        bs.total_runs,
        bs.total_balls_faced,
        bs.total_fours,
        bs.total_sixes,
        bs.total_hundreds,
        bs.total_fifties,
        bs.total_ducks,
        bs.highest_score,
        bs.total_dismissals,

        bws.bowling_matches,
        bws.total_wickets,
        bws.total_runs_conceded,
        bws.total_balls_bowled,
        bws.total_dot_balls,
        bws.total_maidens,
        bws.total_five_wicket_hauls,
        bws.best_wickets_in_match,

        round(
            coalesce(bs.total_runs, 0) / nullif(bs.total_balls_faced, 0) * 100,
            2
        ) as career_strike_rate,

        round(
            coalesce(bws.total_balls_bowled, 0) / nullif(bws.total_wickets, 0),
            2
        ) as bowling_strike_rate

    from player_base pb

    left join batting_stats bs
        on pb.player_id = bs.player_id

    left join bowling_stats bws
        on pb.player_id = bws.player_id

),


final as (

    select
        player_id,
        player_name,

        case
            when coalesce(batting_matches, 0) >= 150
                 and coalesce(bowling_matches, 0) >= 150
                then 'All-rounder'

            when coalesce(batting_matches, 0) > coalesce(bowling_matches, 0)
                then 'Batter'

            when coalesce(bowling_matches, 0) > coalesce(batting_matches, 0)
                then 'Bowler'

            when career_strike_rate is not null
                 and bowling_strike_rate is null
                then 'Batter'

            when bowling_strike_rate is not null
                 and career_strike_rate is null
                then 'Bowler'

            when career_strike_rate >= bowling_strike_rate
                then 'Batter'

            when bowling_strike_rate > career_strike_rate
                then 'Bowler'

            else 'Unknown'
        end as player_role_group,

        coalesce(batting_matches, 0)        as batting_matches,
        coalesce(total_runs, 0)             as total_runs,
        coalesce(total_balls_faced, 0)      as total_balls_faced,
        coalesce(total_fours, 0)            as total_fours,
        coalesce(total_sixes, 0)            as total_sixes,
        coalesce(total_hundreds, 0)         as total_hundreds,
        coalesce(total_fifties, 0)          as total_fifties,
        coalesce(total_ducks, 0)            as total_ducks,
        coalesce(highest_score, 0)          as highest_score,

        round(
            coalesce(total_runs, 0) / nullif(total_dismissals, 0),
            2
        ) as batting_average,

        career_strike_rate,

        coalesce(bowling_matches, 0)            as bowling_matches,
        coalesce(total_wickets, 0)              as total_wickets,
        coalesce(total_runs_conceded, 0)        as total_runs_conceded,
        coalesce(total_balls_bowled, 0)         as total_balls_bowled,
        coalesce(total_dot_balls, 0)            as total_dot_balls,
        coalesce(total_maidens, 0)              as total_maidens,
        coalesce(total_five_wicket_hauls, 0)    as total_five_wicket_hauls,
        coalesce(best_wickets_in_match, 0)      as best_wickets_in_match,

        round(
            coalesce(total_runs_conceded, 0) / nullif(total_wickets, 0),
            2
        ) as bowling_average,

        round(
            coalesce(total_runs_conceded, 0) / nullif(total_balls_bowled, 0) * 6,
            2
        ) as career_economy_rate,

        bowling_strike_rate

    from player_stats

)

select *
from final