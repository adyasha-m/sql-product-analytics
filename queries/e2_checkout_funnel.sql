-- QE2 — Checkout Funnel Drop-off by Entry Channel
-- Owner: Adyasha  |  Last updated: 2026-07-27

-- Business question:
-- Where is checkout leaking, and is the leak the same across paid
-- vs organic acquisition channels?

-- What this tells us:
-- Checkout behavior is consistent across acquisition channels. The largest
-- drop-off occurs between payment and purchase (7.6–8.3%) for every channel,
-- suggesting the primary friction lies in the final checkout step rather than
-- traffic source.

-- PM Action:
-- Investigate the payment → purchase step using session recordings, heatmaps,
-- and payment failure logs to identify friction causing users to abandon
-- checkout after reaching the payment page.

-- Sanity check:
-- 1. Verified purchased <= payment <= shipping <= address <= begin_checkout.
-- 2. Used the maximum checkout step reached per session to avoid double counting.
-- 3. Channel attribution is sourced from ecom.session_channels (first-touch).


with session_step_reached as (

    select
        se.session_id
      , sc.channel
      , max(
            case
                when se.event_type = 'purchase'
                    then 5
                when se.event_type = 'add_payment'
                    then 4
                when se.event_type = 'select_shipping'
                    then 3
                when se.event_type = 'add_address'
                    then 2
                when se.event_type = 'begin_checkout'
                    then 1
                else 0
            end
        ) as max_step
    from ecom.session_events as se
    join ecom.session_channels as sc
        on se.session_id = sc.session_id
    group by
        se.session_id
      , sc.channel

)

select
    ssr.channel
  , count(*) filter (
        where ssr.max_step >= 1
    ) as begin_checkout
  , count(*) filter (
        where ssr.max_step >= 2
    ) as address
  , count(*) filter (
        where ssr.max_step >= 3
    ) as shipping
  , count(*) filter (
        where ssr.max_step >= 4
    ) as payment
  , count(*) filter (
        where ssr.max_step >= 5
    ) as purchased
  , round(
        (
            count(*) filter (
                where ssr.max_step >= 1
            )
            - count(*) filter (
                where ssr.max_step >= 2
            )
        )::numeric
        / nullif(
            count(*) filter (
                where ssr.max_step >= 1
            )
        , 0)
    , 4) as drop_address_pct
  , round(
        (
            count(*) filter (
                where ssr.max_step >= 2
            )
            - count(*) filter (
                where ssr.max_step >= 3
            )
        )::numeric
        / nullif(
            count(*) filter (
                where ssr.max_step >= 2
            )
        , 0)
    , 4) as drop_shipping_pct
  , round(
        (
            count(*) filter (
                where ssr.max_step >= 3
            )
            - count(*) filter (
                where ssr.max_step >= 4
            )
        )::numeric
        / nullif(
            count(*) filter (
                where ssr.max_step >= 3
            )
        , 0)
    , 4) as drop_payment_pct
  , round(
        (
            count(*) filter (
                where ssr.max_step >= 4
            )
            - count(*) filter (
                where ssr.max_step >= 5
            )
        )::numeric
        / nullif(
            count(*) filter (
                where ssr.max_step >= 4
            )
        , 0)
    , 4) as drop_final_pct
from session_step_reached as ssr
where ssr.max_step >= 1
group by
    ssr.channel
order by
    begin_checkout desc;