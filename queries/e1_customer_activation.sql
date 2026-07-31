
-- QE1 — Activation Curve: Time-to-First-Meaningful-Action
-- Owner: Adyasha  |  Last updated: 2026-07-25

-- Business question:
-- How fast do new signups become real users, and how has that changed
-- cohort-over-cohort?

-- What this tells us:
-- Shows how quickly newly acquired users reach their first meaningful milestone
-- (add_to_cart, begin_checkout, or purchase) after signing up. Comparing weekly
-- cohorts helps identify whether onboarding quality or acquisition traffic has
-- changed over time.

-- PM Action:
-- Compare the 2026-05-18 cohort (22% activation) against the surrounding cohorts (16–19%) to identify what changed. 
-- Specifically, investigate onboarding experiments, landing page changes, acquisition-channel mix, 
-- and site performance during that signup week to determine whether the improvement is attributable to product changes or traffic quality.

-- Sanity check:
-- 1. Verified activated_7d <= cohort_size for every cohort.
-- 2. Excluded cohorts before 2026-04-19 because session events were not
--    instrumented before launch.
-- 3. customers.created_at has a known historical timestamp issue confirmed by
--    the dataset owner. Since the original signup timestamps cannot be
--    be recovered, customers.created_at is used as the best available signup
--    proxy, and meaningful events occurring before this timestamp are excluded
--    to preserve the post-signup activation definition.
-- 4. Expect the newest 1–2 cohorts to understate activation because their
--    7-day observation window is incomplete.
-- 5. median_minutes_to_activation and p90_minutes_to_activation are calculated
--    only for users who activated within 7 days.



with signup_cohorts as (

    select
        c.customer_id
      , c.created_at
      , date_trunc('week', c.created_at) as signup_week
    from ecom.customers as c
    where c.created_at >= date '2026-04-19'

)

, first_meaningful_actions as (

    select
        sc.customer_id
      , min(se.occurred_at) as first_action_at
    from signup_cohorts as sc
    join ecom.session_events as se
        on sc.customer_id = se.customer_id
    where se.event_type in (
            'add_to_cart'
          , 'begin_checkout'
          , 'purchase'
        )
      and se.occurred_at >= sc.created_at
    group by
        sc.customer_id

)

, activation_metrics as (

    select
        sc.signup_week
      , sc.customer_id
      , case
            when fma.first_action_at <= sc.created_at + interval '7 day'
                then extract(
                        epoch
                        from (
                            fma.first_action_at - sc.created_at
                        )
                    ) / 60.0
            else null
        end as minutes_to_activation
      , case
            when fma.first_action_at <= sc.created_at + interval '7 day'
                then 1
            else 0
        end as activated_7d
    from signup_cohorts as sc
    left join first_meaningful_actions as fma
        on sc.customer_id = fma.customer_id

)

select
    am.signup_week
  , count(*) as cohort_size
  , sum(am.activated_7d) as activated_7d
  , round(
        sum(am.activated_7d)::numeric
        / count(*)
    , 4) as activation_rate_7d
  , round(
        percentile_cont(0.50)
        within group (
            order by am.minutes_to_activation
        )::numeric
    , 2) as median_minutes_to_activation
  , round(
        percentile_cont(0.90)
        within group (
            order by am.minutes_to_activation
        )::numeric
    , 2) as p90_minutes_to_activation
from activation_metrics as am
group by
    am.signup_week
order by
    am.signup_week;