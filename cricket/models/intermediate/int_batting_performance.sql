{{ config(
    materialized = 'table',
    schema = 'intermediate'
) }}

with batting as (

    select
        match_id,
        innings,
        team,
        batsman as batsman_id,
        runs,
        balls,
        fours,
        sixes,
        strike_rate,
        is_out,
        wicket_type,
        bowler,
        fielders
    from {{ ref('stg_odi_batting_card') }}

),

matches as (

    select
        match_id,
        series_id,
        series_name,
        match_date,
        venue_stadium,
        venue_city,
        venue_country,
        match_winner
    from {{ ref('int_match_summary') }}

),

players_info as (

    select
        player_key,
        player_id,
        player_object_id,
        player_name
    from {{ ref('int_player_lookup') }}

),

final as (

    select
        b.match_id,
        b.innings,
        b.team,
        b.batsman_id,
        coalesce(p.player_name, b.batsman_id) as batsman_name,

        m.series_id,
        m.series_name,
        m.match_date,
        m.venue_stadium,
        m.venue_city,
        m.venue_country,
        m.match_winner,

        b.runs,
        b.balls,
        b.fours,
        b.sixes,
        b.strike_rate,
        b.is_out,
        b.wicket_type,
        b.bowler,
        b.fielders,

        concat(b.match_id, '_', b.batsman_id) as batsman_match_key,
        concat(b.team, '_', b.batsman_id) as team_batsman_key,

        coalesce(b.fours, 0) * 4 as runs_from_fours,
        coalesce(b.sixes, 0) * 6 as runs_from_sixes,
        coalesce(b.fours, 0) + coalesce(b.sixes, 0) as total_boundaries,

        coalesce(b.fours, 0) * 4 + coalesce(b.sixes, 0) * 6 as boundary_runs,

        coalesce(b.runs, 0)
            - (coalesce(b.fours, 0) * 4 + coalesce(b.sixes, 0) * 6) as non_boundary_runs,

        case
            when b.balls > 0 then round(
                (coalesce(b.fours, 0) + coalesce(b.sixes, 0)) / b.balls * 100,
                2
            )
            else 0
        end as boundary_ball_percentage,

        case when b.runs >= 100 then 1 else 0 end as hundred_flag,
        case when b.runs >= 50 and b.runs < 100 then 1 else 0 end as fifty_flag,
        case when b.runs = 0 then 1 else 0 end as duck_flag,

        case
            when b.runs >= 100 then '100+'
            when b.runs >= 50 then '50-99'
            when b.runs >= 30 then '30-49'
            when b.runs >= 10 then '10-29'
            when b.runs > 0 then '1-9'
            when b.runs = 0 then 'Duck'
            else 'Unknown'
        end as runs_bucket,

        case
            when b.strike_rate >= 150 then 'Explosive'
            when b.strike_rate >= 100 then 'Fast'
            when b.strike_rate >= 70 then 'Moderate'
            when b.strike_rate > 0 then 'Slow'
            else 'No Score'
        end as strike_rate_bucket,

        case
            when not b.is_out then 'Not Out'
            when b.wicket_type ilike '%caught%' then 'Caught'
            when b.wicket_type ilike '%bowled%' then 'Bowled'
            when b.wicket_type ilike '%lbw%' then 'LBW'
            when b.wicket_type ilike '%run out%' then 'Run Out'
            when b.wicket_type ilike '%stumped%' then 'Stumped'
            when b.wicket_type is null then 'Unknown'
            else 'Other'
        end as dismissal_group,

        case
            when b.team = m.match_winner then 1
            else 0
        end as batsman_team_won_flag

    from batting b
    left join matches m
        on b.match_id = m.match_id
    left join players_info p
        on b.batsman_id = p.player_key

)

select *
from final