-- S1 — Monthly MRR Movement Decomposition
-- Owner: Adyasha  |  Last updated: 2026-07-28

-- Business question:
-- How did MRR change last month—and what drove the change? New,
-- expansion, contraction, churn, or reactivation?

-- What this tells us:
-- Decomposes monthly MRR movement into the five canonical revenue drivers,
-- making it easy to distinguish growth from new and existing customers versus
-- revenue lost through downgrades and churn.

-- PM Action:
-- Churn MRR peaked at approximately $13.8K in March 2026, making it the
-- largest negative revenue movement in the analysis period. Segment March
-- churn by plan, account size, and customer tenure to identify the customer
-- cohort driving the increase before implementing retention initiatives.

-- Sanity check:
-- 1. Excluded trial_started events from MRR calculations.
-- 2. Excluded future-dated events after 2026-06-15.
-- 3. Verified net_new_mrr equals the sum of new, expansion, contraction,
--    churn, and reactivation MRR for every month.
-- 4. Historical month-end MRR snapshots are not available in the provided
--    schema, so ending MRR reconciliation could not be independently validated.

with classified_events as (

    select
        date_trunc('month', se.event_time) as month
      , case
            when se.event_type = 'subscription_started'
             and se.mrr_delta > 0
             and exists (
                    select
                        1
                    from saas.subscription_events as prev
                    where prev.account_id = se.account_id
                      and prev.event_type = 'cancelled'
                      and prev.event_time < se.event_time
                )
                then 'reactivation'

            when se.event_type in (
                    'subscription_started'
                  , 'trial_converted'
                )
             and se.mrr_delta > 0
                then 'new'

            when se.event_type = 'plan_changed'
             and se.mrr_delta > 0
                then 'expansion'

            when se.event_type in (
                    'seat_add'
                  , 'addon_attach'
                )
                then 'expansion'

            when se.event_type = 'plan_changed'
             and se.mrr_delta < 0
                then 'contraction'

            when se.event_type = 'cancelled'
                then 'churn'
        end as bucket

      , coalesce(se.mrr_delta, 0) as mrr_delta

    from saas.subscription_events as se

    where se.event_type <> 'trial_started'
      and se.event_time <= timestamp '2026-06-15 23:59:59'

)

select
    ce.month

  , coalesce(
        sum(ce.mrr_delta) filter (
            where ce.bucket = 'new'
        )
    , 0) as new_mrr

  , coalesce(
        sum(ce.mrr_delta) filter (
            where ce.bucket = 'expansion'
        )
    , 0) as expansion_mrr

  , coalesce(
        sum(ce.mrr_delta) filter (
            where ce.bucket = 'contraction'
        )
    , 0) as contraction_mrr

  , coalesce(
        sum(ce.mrr_delta) filter (
            where ce.bucket = 'churn'
        )
    , 0) as churn_mrr

  , coalesce(
        sum(ce.mrr_delta) filter (
            where ce.bucket = 'reactivation'
        )
    , 0) as reactivation_mrr

  , coalesce(
        sum(ce.mrr_delta)
    , 0) as net_new_mrr

from classified_events as ce

where ce.bucket is not null

group by
    ce.month

order by
    ce.month;