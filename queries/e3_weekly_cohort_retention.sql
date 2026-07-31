-- QE3 — Cohort Retention Curve (Weekly, Behavioral)
-- Owner: Adyasha  |  Last updated: 2026-07-27

-- Business question:
-- Of users who signed up in week W, what fraction returned and performed a
-- meaningful action in weeks W+1 through W+4?

-- What this tells us:
-- Weekly behavioral retention remains below 20% in Week 1 for all fully
-- observed cohorts, indicating that post-signup activation is the primary
-- bottleneck rather than long-term engagement.

-- PM Action:
-- Since Week 1 retention is consistently below 20%, prioritize improving
-- post-signup activation by investigating onboarding, first-session
-- engagement, and early lifecycle messaging before investing in long-term
-- retention initiatives.

-- Sanity check:
-- 1. Verified w0_active = cohort_size for every cohort.
-- 2. Computed retention using week_index relative to signup date, not calendar week.
-- 3. Excluded cohorts before 2026-04-19 because session events were uninstrumented.
-- 4. customers.created_at has a known historical timestamp issue; cohorts are
--    based on the best available signup proxy, and only post-signup sessions
--    are included in retention calculations.
-- 5. The most recent cohorts have incomplete observation windows, so later-week
--    retention should be interpreted with caution.

with cohort_customers as (

    select
        c.customer_id
      , c.created_at
      , date_trunc('week', c.created_at) as cohort_week
    from ecom.customers as c
    where c.created_at >= date '2026-04-19'

)

, meaningful_sessions as (

    select distinct
        cc.customer_id
      , cc.cohort_week
      , cc.created_at
      , s.session_id
      , s.started_at as session_started_at
    from cohort_customers as cc
    join ecom.sessions as s
        on cc.customer_id = s.customer_id
    join ecom.session_events as se
        on s.session_id = se.session_id
    where se.event_type in (
            'product_view'
          , 'add_to_cart'
          , 'purchase'
        )
      and s.started_at >= cc.created_at

)

, session_weeks as (

    select
        ms.customer_id
      , ms.cohort_week
      , floor(
            extract(
                epoch
                from (
                    ms.session_started_at - ms.created_at
                )
            ) / (86400 * 7)
        )::int as week_index
    from meaningful_sessions as ms

)

select
    cc.cohort_week
  , count(*) as cohort_size
  , count(*) as w0_active
  , count(distinct sw.customer_id) filter (
        where sw.week_index = 1
    ) as w1_retained
  , count(distinct sw.customer_id) filter (
        where sw.week_index = 2
    ) as w2_retained
  , count(distinct sw.customer_id) filter (
        where sw.week_index = 3
    ) as w3_retained
  , count(distinct sw.customer_id) filter (
        where sw.week_index = 4
    ) as w4_retained
  , round(
        count(distinct sw.customer_id) filter (
            where sw.week_index = 1
        )::numeric
        / nullif(count(*), 0)
    , 4) as w1_retention_rate
  , round(
        count(distinct sw.customer_id) filter (
            where sw.week_index = 2
        )::numeric
        / nullif(count(*), 0)
    , 4) as w2_retention_rate
  , round(
        count(distinct sw.customer_id) filter (
            where sw.week_index = 3
        )::numeric
        / nullif(count(*), 0)
    , 4) as w3_retention_rate
  , round(
        count(distinct sw.customer_id) filter (
            where sw.week_index = 4
        )::numeric
        / nullif(count(*), 0)
    , 4) as w4_retention_rate
from cohort_customers as cc
left join session_weeks as sw
    on cc.customer_id = sw.customer_id
   and cc.cohort_week = sw.cohort_week
group by
    cc.cohort_week
order by
    cc.cohort_week;