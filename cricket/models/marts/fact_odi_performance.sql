{{ config(
    materialized = 'table',
    schema = 'marts'
) }}

with team_performance as (

    select
        match_id,

        'TEAM' as performance_type,

        team_name,
        md5(upper(trim(team_name))) as team_key,

        cast(null as varchar) as player_id,
        cast(null as varchar) as player_name,

        opposition_name,
        cast(null as number) as innings,

        runs_scored,
        wickets_lost,

        runs_conceded,
        wickets_taken,

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

        

        match_date,
        series_id,
        series_name,

        venue_stadium,
        venue_city,
        venue_country,

        md5(
            coalesce(upper(trim(venue_stadium)), '')
            || '|'
            || coalesce(upper(trim(venue_city)), '')
            || '|'
            || coalesce(upper(trim(venue_country)), '')
        ) as venue_key,

        match_winner

    from {{ ref('int_team_innings_performance') }}

),

batting_performance as (

    select
        match_id,

        'BATTING' as performance_type,

        team as team_name,
        md5(upper(trim(team))) as team_key,

        cast(batsman_id as varchar) as player_id,
        batsman_name as player_name,

        cast(null as varchar) as opposition_name,
        innings,

        runs as runs_scored,
        cast(null as number) as wickets_lost,

        cast(null as number) as runs_conceded,
        cast(null as number) as wickets_taken,

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


        match_date,
        series_id,
        series_name,

        venue_stadium,
        venue_city,
        venue_country,

        md5(
            coalesce(upper(trim(venue_stadium)), '')
            || '|'
            || coalesce(upper(trim(venue_city)), '')
            || '|'
            || coalesce(upper(trim(venue_country)), '')
        ) as venue_key,

        match_winner

    from {{ ref('int_batting_performance') }}

),

bowling_performance as (

    select
        match_id,

        'BOWLING' as performance_type,

        team as team_name,
        md5(upper(trim(team))) as team_key,

        cast(bowler_id as varchar) as player_id,
        bowler_name as player_name,

        opposition as opposition_name,
        innings,

        cast(null as number) as runs_scored,
        cast(null as number) as wickets_lost,

        runs_conceded,
        wickets as wickets_taken,

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

        

        match_date,
        series_id,
        series_name,

        venue_stadium,
        venue_city,
        venue_country,

        md5(
            coalesce(upper(trim(venue_stadium)), '')
            || '|'
            || coalesce(upper(trim(venue_city)), '')
            || '|'
            || coalesce(upper(trim(venue_country)), '')
        ) as venue_key,

        match_winner

    from {{ ref('int_bowling_performance') }}

),

unioned as (

    select * from team_performance
    union all
    select * from batting_performance
    union all
    select * from bowling_performance

),

final as (

    select
        md5(
            coalesce(cast(match_id as varchar), '')
            || '|'
            || coalesce(cast(team_key as varchar), '')
            || '|'
            || coalesce(cast(player_id as varchar), '')
            || '|'
            || coalesce(performance_type, '')
            || '|'
            || coalesce(cast(innings as varchar), '')
        ) as performance_key,

        match_id,
        team_key,
        player_id,
        venue_key,

        performance_type,

        team_name,
        player_name,
        opposition_name,
        innings,

        runs_scored,
        wickets_lost,

        runs_conceded,
        wickets_taken,

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

        

        match_date,
        series_id,
        series_name,
        venue_stadium,
        venue_city,
        venue_country,
        match_winner

    from unioned

)

select *
from final