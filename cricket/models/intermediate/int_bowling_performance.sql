{{ config(
    materialized = 'table',
    schema = 'intermediate'
) }}

with bowling as (

    select
        match_id,
        innings,
        team,
        opposition,
        bowler_id,
        overs,
        balls,
        maidens,
        runs_conceded,
        wickets,
        economy,
        dots,
        fours,
        sixes,
        wides,
        no_balls

    from {{ ref('stg_odi_bowling_card') }}

),

matches as (

    select
        match_id,
        series_id,
        series_name,
        match_date,
        venue_key,
        venue_city,
        venue_country,
        match_winner

    from {{ ref('int_match_summary') }}

),

final as (

    select
        bw.match_id,
        bw.innings,
        bw.team,
        bw.opposition,
        bw.bowler_id,

        m.series_id,
        m.series_name,
        m.match_date,
        m.venue_key,
        m.venue_city,
        m.venue_country,
        m.match_winner,

        bw.overs,
        bw.balls,
        bw.maidens,
        bw.runs_conceded,
        bw.wickets,
        bw.economy,
        bw.dots,
        bw.fours,
        bw.sixes,
        bw.wides,
        bw.no_balls,

        concat(bw.match_id, '_', bw.bowler_id) as bowler_match_key,

        concat(bw.team, '_', bw.bowler_id) as team_bowler_key,

        coalesce(bw.wides, 0) + coalesce(bw.no_balls, 0) as extras_conceded,

        coalesce(bw.fours, 0) + coalesce(bw.sixes, 0) as boundaries_conceded,

        coalesce(bw.fours, 0) * 4
            + coalesce(bw.sixes, 0) * 6 as boundary_runs_conceded,

        case
            when bw.balls > 0 then round(coalesce(bw.dots, 0) / bw.balls * 100, 2)
            else 0
        end as dot_ball_percentage,

        case
            when bw.balls > 0 then round(
                (
                    coalesce(bw.fours, 0) + coalesce(bw.sixes, 0)
                ) / bw.balls * 100,
                2
            )
            else 0
        end as boundary_ball_percentage_conceded,

        case
            when bw.wickets >= 5 then 1
            else 0
        end as five_wicket_haul_flag,

        case
            when bw.wickets >= 4 then 1
            else 0
        end as four_plus_wicket_flag,

        case
            when bw.wickets >= 5 then '5+ wickets'
            when bw.wickets = 4 then '4 wickets'
            when bw.wickets = 3 then '3 wickets'
            when bw.wickets = 2 then '2 wickets'
            when bw.wickets = 1 then '1 wicket'
            else 'No wicket'
        end as wicket_bucket,

        case
            when bw.economy <= 3 then 'Excellent'
            when bw.economy <= 5 then 'Good'
            when bw.economy <= 7 then 'Average'
            when bw.economy > 7 then 'Expensive'
            else 'Unknown'
        end as economy_bucket,

        case
            when coalesce(bw.wides, 0) + coalesce(bw.no_balls, 0) = 0 then 'Disciplined'
            when coalesce(bw.wides, 0) + coalesce(bw.no_balls, 0) <= 2 then 'Acceptable'
            else 'Poor Discipline'
        end as discipline_bucket,

        case
            when bw.team = m.match_winner then 1
            else 0
        end as bowler_team_won_flag

    from bowling bw

    left join matches m
        on bw.match_id = m.match_id

)

select *
from final