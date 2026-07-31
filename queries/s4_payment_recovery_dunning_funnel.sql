-- QS4 — Dunning Funnel by Failure Reason
-- Owner: Adyasha | Last Updated: 2026-07-29
--
-- Business Question:
-- Of failed first payment attempts in the most recent completed quarter, what
-- fraction recovered on retry by failure reason, and where should dunning
-- improvements be prioritized?

-- Assumption:
-- MRR is derived by joining payment_attempts to invoices on invoice_id and
-- invoices to subscriptions on subscription_id, since
-- payment_attempts.subscription_id is sparsely populated.

-- PM Action:
-- Prioritize the failure reason with the highest
-- mrr_at_risk × (1 - recovery_rate). Ship smart retry scheduling for
-- insufficient_funds before investing in lower-impact failure reasons.

-- Sanity Checks:
-- 1. eventually_recovered <= first_attempt_failures
-- 2. recovery_rate is between 0 and 1
-- 3. mrr_recovered <= mrr_at_risk for every failure reason


with first_attempt_failures as (

    select
        pa.invoice_id
      , pa.failure_reason
      , sub.mrr

    from saas.payment_attempts as pa

    inner join saas.invoices as inv
        on pa.invoice_id = inv.invoice_id

    inner join saas.subscriptions as sub
        on inv.subscription_id = sub.subscription_id

    where pa.attempt_number = 1
      and pa.status = 'failed'
      and pa.attempted_at >= (
            date_trunc('quarter', current_date)
            - interval '3 months'
      )
      and pa.attempted_at < date_trunc('quarter', current_date)

)

, successful_retries as (

    select
        pa.invoice_id
      , min(pa.attempt_number) as recovery_attempt

    from saas.payment_attempts as pa

    where pa.status = 'succeeded'
      and pa.attempt_number > 1

    group by
        pa.invoice_id

)

, invoice_outcomes as (

    select
        faf.invoice_id
      , faf.failure_reason
      , faf.mrr

      , case
            when sr.recovery_attempt is not null
                then 1
            else 0
        end as recovered

      , sr.recovery_attempt

    from first_attempt_failures as faf

    left join successful_retries as sr
        on faf.invoice_id = sr.invoice_id

)

select
    io.failure_reason

  , count(*) as first_attempt_failures

  , sum(io.recovered) as eventually_recovered

  , round(
        (
            sum(io.recovered)::numeric
            / count(*)
        )
    , 3) as recovery_rate

  , round(
        percentile_cont(0.5)
        within group (
            order by io.recovery_attempt
        )::numeric
    , 1) as median_attempts_to_recovery

  , round(
        sum(io.mrr)
    , 2) as mrr_at_risk

  , round(
        sum(io.mrr)
        filter (
            where io.recovered = 1
        )
    , 2) as mrr_recovered

  , round(
        (
            sum(io.mrr)
            * (
                1
                - (
                    sum(io.recovered)::numeric
                    / count(*)
                )
            )
        )
    , 2) as opportunity_score

from invoice_outcomes as io

group by
    io.failure_reason

order by
    opportunity_score desc;