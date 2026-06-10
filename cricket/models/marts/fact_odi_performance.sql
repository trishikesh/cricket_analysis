{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with team_performance as (

    select
        match_id,
        team_match_key as performance_natural_key,

        'TEAM' as performance_type,

        team_name,
        cast(null as varchar) as player_name,

        opposition_name,
        team_position as innings,

        runs_scored,
        wickets_lost,
        extras_received,

        runs_conceded,
        wickets_taken,
        extras_conceded,

        cast(null as number) as balls_faced,
        cast(null as number) as fours,
        cast(null as number) as sixes,
        cast(null as float) as strike_rate,

        cast(null as number) as overs,
        cast(null as number) as balls_bowled,
        cast(null as number) as maidens,
        cast(null as float) as economy,
        cast(null as number) as dots,
        cast(null as number) as wides,
        cast(null as number) as no_balls,

        win_flag,
        loss_flag,
        toss_win_flag,
        toss_and_match_win_flag,
        all_out_flag,

        cast(null as number) as hundred_flag,
        cast(null as number) as fifty_flag,
        cast(null as number) as duck_flag,
        cast(null as number) as five_wicket_haul_flag,

        score_bucket as performance_bucket,
        batting_stability_bucket as secondary_bucket,

        team_run_margin as run_margin,

        match_date,
        series_id,
        series_name,
        venue_key,
        venue_city,
        venue_country,
        match_winner

    from {{ ref('int_team_innings_performance') }}

),

batting_performance as (

    select
        match_id,
        batsman_match_key as performance_natural_key,

        'BATTING' as performance_type,

        team as team_name,
        batsman as player_name,

        cast(null as varchar) as opposition_name,
        innings,

        runs as runs_scored,
        cast(null as number) as wickets_lost,
        cast(null as number) as extras_received,

        cast(null as number) as runs_conceded,
        cast(null as number) as wickets_taken,
        cast(null as number) as extras_conceded,

        balls as balls_faced,
        fours,
        sixes,
        strike_rate,

        cast(null as number) as overs,
        cast(null as number) as balls_bowled,
        cast(null as number) as maidens,
        cast(null as float) as economy,
        cast(null as number) as dots,
        cast(null as number) as wides,
        cast(null as number) as no_balls,

        batsman_team_won_flag as win_flag,
        case when batsman_team_won_flag = 0 then 1 else 0 end as loss_flag,
        cast(null as number) as toss_win_flag,
        cast(null as number) as toss_and_match_win_flag,
        cast(null as number) as all_out_flag,

        hundred_flag,
        fifty_flag,
        duck_flag,
        cast(null as number) as five_wicket_haul_flag,

        runs_bucket as performance_bucket,
        strike_rate_bucket as secondary_bucket,

        cast(null as number) as run_margin,

        match_date,
        series_id,
        series_name,
        venue_key,
        venue_city,
        venue_country,
        match_winner

    from {{ ref('int_batting_performance') }}

),

bowling_performance as (

    select
        match_id,
        bowler_match_key as performance_natural_key,

        'BOWLING' as performance_type,

        team as team_name,
        bowler_id as player_name,

        opposition as opposition_name,
        innings,

        cast(null as number) as runs_scored,
        cast(null as number) as wickets_lost,
        cast(null as number) as extras_received,

        runs_conceded,
        wickets as wickets_taken,
        extras_conceded,

        cast(null as number) as balls_faced,
        fours,
        sixes,
        cast(null as float) as strike_rate,

        overs,
        balls as balls_bowled,
        maidens,
        economy,
        dots,
        wides,
        no_balls,

        bowler_team_won_flag as win_flag,
        case when bowler_team_won_flag = 0 then 1 else 0 end as loss_flag,
        cast(null as number) as toss_win_flag,
        cast(null as number) as toss_and_match_win_flag,
        cast(null as number) as all_out_flag,

        cast(null as number) as hundred_flag,
        cast(null as number) as fifty_flag,
        cast(null as number) as duck_flag,
        five_wicket_haul_flag,

        wicket_bucket as performance_bucket,
        economy_bucket as secondary_bucket,

        cast(null as number) as run_margin,

        match_date,
        series_id,
        series_name,
        venue_key,
        venue_city,
        venue_country,
        match_winner

    from {{ ref('int_bowling_performance') }}

),

unioned as (

    select *
    from team_performance

    union all

    select *
    from batting_performance

    union all

    select *
    from bowling_performance

),

final as (

    select
        md5(
            coalesce(cast(match_id as varchar), '')
            || '_'
            || coalesce(performance_natural_key, '')
            || '_'
            || coalesce(performance_type, '')
        ) as performance_key,

        md5(cast(match_id as varchar)) as match_key,

        md5(coalesce(team_name, '')) as team_key_by_name,

        md5(coalesce(player_name, '') || '_' || coalesce(team_name, '')) as player_key,

        md5(coalesce(venue_key, '')) as venue_key_hash,

        match_id,
        performance_natural_key,
        performance_type,

        team_name,
        player_name,
        opposition_name,
        innings,

        runs_scored,
        wickets_lost,
        extras_received,

        runs_conceded,
        wickets_taken,
        extras_conceded,

        balls_faced,
        fours,
        sixes,
        strike_rate,

        overs,
        balls_bowled,
        maidens,
        economy,
        dots,
        wides,
        no_balls,

        win_flag,
        loss_flag,
        toss_win_flag,
        toss_and_match_win_flag,
        all_out_flag,

        hundred_flag,
        fifty_flag,
        duck_flag,
        five_wicket_haul_flag,

        performance_bucket,
        secondary_bucket,
        run_margin,

        match_date,
        series_id,
        series_name,
        venue_key,
        venue_city,
        venue_country,
        match_winner

    from unioned

)

select *
from final