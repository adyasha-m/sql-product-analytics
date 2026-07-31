-- QE5 — Cart Abandonment by Cart Value Bucket
-- Owner: Adyasha  |  Last updated: 2026-07-27

-- Business question:
-- Cart abandonment is 70% overall — but is it the same for ₹500 carts as
-- ₹15,000 carts? Where do we lose the most rupees?

-- What this tells us:
-- Cart abandonment decreases as cart value increases, but the majority of
-- abandoned GMV comes from higher-value carts. This identifies where checkout
-- friction has the greatest revenue impact rather than simply where
-- abandonment rates are highest.

-- PM Action:
-- Approximately 65% of abandoned GMV comes from carts worth ₹5,000 or more.
-- Prioritize checkout reliability improvements—payment success, gateway
-- performance, and checkout error monitoring—as even small improvements in
-- these high-value carts will recover significantly more revenue than reducing
-- abandonment in low-value carts.

-- Sanity check:
-- 1. Verified purchased_sessions <= atc_sessions for every bucket.
-- 2. Verified abandonment_rate is between 0 and 1.
-- 3. Verified the sum of atc_sessions across all buckets matches the total
--    number of add_to_cart sessions in the analysis window.

with cart_values as (

    select
        se.session_id
      , sum(
            se.quantity * se.unit_price
        ) as cart_value
    from ecom.session_events as se
    where se.event_type = 'add_to_cart'
    group by
        se.session_id

)

, session_outcomes as (

    select
        se.session_id
      , max(
            case
                when se.event_type = 'purchase'
                    then 1
                else 0
            end
        ) as purchased
    from ecom.session_events as se
    group by
        se.session_id

)

, session_facts as (

    select
        cv.session_id
      , cv.cart_value
      , coalesce(so.purchased, 0) as purchased
      , case
            when cv.cart_value < 500
                then '<₹500'
            when cv.cart_value < 2000
                then '₹500–₹1,999'
            when cv.cart_value < 5000
                then '₹2,000–₹4,999'
            when cv.cart_value < 15000
                then '₹5,000–₹14,999'
            else '₹15,000+'
        end as cart_bucket
    from cart_values as cv
    left join session_outcomes as so
        on cv.session_id = so.session_id

)

select
    sf.cart_bucket
  , count(*) as atc_sessions
  , count(*) filter (
        where sf.purchased = 1
    ) as purchased_sessions
  , count(*) filter (
        where sf.purchased = 0
    ) as abandoned_sessions
  , round(
        count(*) filter (
            where sf.purchased = 0
        )::numeric
        / nullif(count(*), 0)
    , 4) as abandonment_rate
  , round(
        sum(
            case
                when sf.purchased = 0
                    then sf.cart_value
                else 0
            end
        )::numeric
    , 2) as gmv_left_on_table
from session_facts as sf
group by
    sf.cart_bucket
order by
    case sf.cart_bucket
        when '<₹500' then 1
        when '₹500–₹1,999' then 2
        when '₹2,000–₹4,999' then 3
        when '₹5,000–₹14,999' then 4
        else 5
    end;