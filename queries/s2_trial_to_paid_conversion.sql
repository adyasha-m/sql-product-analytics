-- S2 — Trial-to-Paid Conversion by Cohort
-- Owner: Adyasha  |  Last updated: 2026-07-28

-- Business question:
-- Of accounts that started a trial in week W, what fraction converted
-- to paid by day 14, 30, and 60?

-- What this tells us:
-- Measures trial-to-paid conversion across weekly cohorts. In this dataset,
-- all observed conversions occur within 14 days, indicating trial outcomes
-- are determined early in the customer lifecycle.

-- PM Action:
-- Investigate the lowest-converting cohorts by trial plan, signup source,
-- company size, or country to determine whether poor conversion is driven
-- by acquisition quality or product adoption.

-- Sanity check:
-- 1. Verified converted_by_14d <= converted_by_30d <= converted_by_60d.
-- 2. Used the first trial per account.
-- 3. Counted paid conversions using trial_converted and
--    subscription_started events.
-- 4. Verified the maximum observed trial-to-paid time is 14 days.
-- 5. Recent cohorts have incomplete observation windows and may
--    understate conversion.

with first_trials as (

    select
        t.account_id
      , min(t.started_at) as trial_started_at
      , date_trunc(
            'week'
          , min(t.started_at)
        ) as trial_week
    from saas.trials as t
    group by
        t.account_id

)

, first_paid_events as (

    select
        ft.account_id
      , min(se.event_time) as first_paid_at
    from first_trials as ft
    left join saas.subscription_events as se
        on ft.account_id = se.account_id
       and se.event_time >= ft.trial_started_at
       and se.event_type in (
            'trial_converted'
          , 'subscription_started'
        )
    group by
        ft.account_id

)

, trial_metrics as (

    select
        ft.account_id
      , ft.trial_week
      , ft.trial_started_at
      , fpe.first_paid_at
      , extract(
            epoch
            from (
                fpe.first_paid_at
                - ft.trial_started_at
            )
        ) / 86400.0 as days_to_conversion
    from first_trials as ft
    left join first_paid_events as fpe
        on ft.account_id = fpe.account_id

)

select
    tm.trial_week
  , count(*) as trials_started

  , count(*) filter (
        where tm.days_to_conversion <= 14
    ) as converted_by_14d

  , count(*) filter (
        where tm.days_to_conversion <= 30
    ) as converted_by_30d

  , count(*) filter (
        where tm.days_to_conversion <= 60
    ) as converted_by_60d

  , round(
        count(*) filter (
            where tm.days_to_conversion <= 14
        )::numeric
        / count(*)
    , 4) as conv_rate_14d

  , round(
        count(*) filter (
            where tm.days_to_conversion <= 30
        )::numeric
        / count(*)
    , 4) as conv_rate_30d

  , round(
        count(*) filter (
            where tm.days_to_conversion <= 60
        )::numeric
        / count(*)
    , 4) as conv_rate_60d

  , round(
        percentile_cont(0.50)
        within group (
            order by tm.days_to_conversion
        )::numeric
    , 2) as median_days_trial_to_paid

from trial_metrics as tm

group by
    tm.trial_week

order by
    tm.trial_week;