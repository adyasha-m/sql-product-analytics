-- QS5 — Expansion Revenue: Who's Upgrading and Why
-- Owner: Adyasha | Last Updated: 2026-07-29
--
-- Business Question:
-- Of accounts that expanded MRR during the six-month reporting window ending
-- on the assignment as-of date (2026-06-15), what was the dominant expansion
-- vector: seats added, plan upgrade, or add-on attach?

-- Assumptions:
-- 1. The reporting window matches Query S1 exactly to satisfy the required
--    reconciliation check and excludes the 234 future-dated legacy rows.
-- 2. Expansion revenue is measured directly from
--    saas.subscription_events.mrr_delta.
-- 3. Signup age is measured using saas.accounts.signup_date.
-- 4. Median time to expansion is calculated using each account's first
--    qualifying expansion event for that expansion type.

-- PM Action:
-- Seat additions were the largest contributor to Expansion MRR. Segment
-- seat expansion by customer size, plan tier, and industry to identify
-- high-growth accounts and target expansion initiatives where additional
-- seats are most likely.

-- Sanity Checks:
-- 1. Sum(expansion_mrr_total) reconciles exactly with Expansion MRR from
--    Query S1 for the same reporting window.
-- 2. expansion_events >= accounts_expanded.
-- 3. expansion_mrr_per_account =
--      expansion_mrr_total / accounts_expanded.

with analysis_window as (

    select
        timestamp '2025-12-01 00:00:00' as analysis_start_at
      , timestamp '2026-06-15 23:59:59' as analysis_end_at

)

, expansion_events as (

    select
        se.event_id
      , se.account_id
      , a.signup_date::timestamp as signup_at
      , se.event_time

      , case
            when se.event_type = 'seat_add'
                then 'seats_added'

            when se.event_type = 'addon_attach'
                then 'addon'

            when se.event_type = 'plan_changed'
             and se.mrr_delta > 0
                then 'plan_upgrade'
        end as expansion_type

      , se.mrr_delta

    from saas.subscription_events as se

    inner join saas.accounts as a
        on se.account_id = a.account_id

    cross join analysis_window as aw

    where se.event_time >= aw.analysis_start_at
      and se.event_time <= aw.analysis_end_at
      and (
            se.event_type = 'seat_add'
         or se.event_type = 'addon_attach'
         or (
                se.event_type = 'plan_changed'
            and se.mrr_delta > 0
         )
      )

)

, event_summary as (

    select
        ee.expansion_type

      , count(*) as expansion_events

      , count(distinct ee.account_id) as accounts_expanded

      , sum(ee.mrr_delta) as expansion_mrr_total

    from expansion_events as ee

    group by
        ee.expansion_type

)

, first_expansion as (

    select distinct on (
        ee.account_id
      , ee.expansion_type
    )

        ee.account_id
      , ee.expansion_type
      , ee.signup_at
      , ee.event_time

    from expansion_events as ee

    order by
        ee.account_id
      , ee.expansion_type
      , ee.event_time
      , ee.event_id

)

, median_summary as (

    select
        fe.expansion_type

      , round(
            percentile_cont(0.5)
            within group (
                order by (
                    fe.event_time::date
                    - fe.signup_at::date
                )
            )::numeric
        , 0) as median_days_from_signup_to_expansion

    from first_expansion as fe

    group by
        fe.expansion_type

)

select
    es.expansion_type

  , es.expansion_events

  , es.accounts_expanded

  , round(
        es.expansion_mrr_total
    , 2) as expansion_mrr_total

  , round(
        es.expansion_mrr_total
        / nullif(
            es.accounts_expanded
          , 0
        )
    , 2) as expansion_mrr_per_account

  , ms.median_days_from_signup_to_expansion

from event_summary as es

inner join median_summary as ms
    on es.expansion_type = ms.expansion_type

order by
    expansion_mrr_total desc;