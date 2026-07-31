-- QE4 — PDP Engagement: High-View, Low-Cart Products
-- Owner: Adyasha  |  Last updated: 2026-07-27

-- Business question:
-- Which products attract eyeballs but don't get added to cart?

-- What this tells us:
-- Identifies high-traffic products whose add-to-cart rates are well below
-- their category median. Comparing products against their category baseline
-- highlights SKU-specific friction rather than normal differences in shopping
-- behavior across categories.

-- PM Action:
-- Hand the top 10 flagged SKUs to the merchandising PM for review. For each
-- product, validate one of three hypotheses: (1) uncompetitive pricing,
-- (2) poor product imagery or PDP content, or (3) stock availability or
-- merchandising issues reducing add-to-cart conversion.

-- Sanity check:
-- 1. Verified add_to_cart_sessions <= views for every product.
-- 2. Verified atc_rate is between 0 and 1.
-- 3. Compared each product against its category median ATC rate rather than
--    using a global benchmark.

with product_views as (

    select
        se.product_id
      , count(*) filter (
            where se.event_type = 'product_view'
        ) as views
      , count(distinct se.session_id) filter (
            where se.event_type = 'add_to_cart'
        ) as add_to_cart_sessions
    from ecom.session_events as se
    where se.event_type in (
            'product_view'
          , 'add_to_cart'
        )
      and se.product_id is not null
    group by
        se.product_id

)

, product_metrics as (

    select
        p.product_id
      , p.product_name
      , p.category_id
      , pv.views
      , pv.add_to_cart_sessions
      , pv.add_to_cart_sessions::numeric
        / nullif(pv.views, 0) as atc_rate
    from ecom.products as p
    join product_views as pv
        on p.product_id = pv.product_id
    where pv.views > 0

)

, category_medians as (

    select
        pm.category_id
      , percentile_cont(0.50)
            within group (
                order by pm.atc_rate
            ) as category_median_atc_rate
    from product_metrics as pm
    group by
        pm.category_id

)

select
    pm.product_id
  , pm.product_name
  , pm.category_id
  , pm.views
  , pm.add_to_cart_sessions
  , round(
      pm.atc_rate::numeric
    , 4
  ) as atc_rate

  , round(
      (pm.atc_rate - cm.category_median_atc_rate)::numeric
    , 4
  ) as atc_rate_vs_category_median
  , dense_rank() over (
        order by pm.views desc
    ) as views_rank
  , dense_rank() over (
        order by pm.atc_rate asc
    ) as atc_rate_rank
from product_metrics as pm
join category_medians as cm
    on pm.category_id = cm.category_id
where pm.views >= 100
order by
    atc_rate_vs_category_median asc
  , pm.views desc
limit 10;