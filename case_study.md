# B2C vs B2B: How Funnels and Retention Actually Differ

[https://github.com/adyasha-m/sql-product-analytics](github)

## Introduction

I analyzed two product datasets using SQL one from a B2C e-commerce business and another from a SaaS product to compare how the same analytical concepts translate across different business models. While both relied on funnels, cohorts, retention, and conversion metrics, the questions they answered were fundamentally different. A checkout funnel measured customer progression through a purchase session, whereas a SaaS funnel tracked an account's journey from trial to paid subscription. Likewise, retention represented repeat customer behaviour in one dataset and recurring revenue in the other.

This case study explores how the same analytical toolkit can lead to very different product decisions depending on the business context.

---

## At a Glance

|                        | **B2C E-commerce**        | **SaaS**                    |
| ---------------------- | ------------------------- | --------------------------- |
| **Unit of Analysis**   | Session / Customer        | Account / Subscription      |
| **Primary Conversion** | Purchase                  | Paid Subscription           |
| **Retention**          | Repeat Customer Behaviour | Recurring Revenue (GRR/NRR) |
| **Growth**             | Repeat Purchases          | Expansion Revenue           |
| **Time Horizon**       | Minutes to Days           | Weeks to Months             |

---

# 1. Funnel Shape: Same Framework, Different Journey

Funnels are one of the most widely used tools in product analytics, but they looked remarkably different across the two datasets.

In the B2C e-commerce dataset, the funnel was **session-grained**. Users progressed through **begin checkout → address → shipping → payment → purchase**, often within a single browsing session. Every stage represented immediate customer behaviour, making the primary objective straightforward: identify where users abandoned the purchase journey and reduce friction before the transaction was completed.

The SaaS funnel, however, operated on a much longer timescale. Instead of tracking actions within a single session, it followed an account from **trial** to **paid subscription** over days or even weeks. The business question shifted from _"Where did the user leave?"_ to _"Did the account experience enough value during the trial to become a paying customer?"_ Although both analyses measured progression through sequential events, one optimized a single transaction while the other optimized the beginning of a long-term customer relationship.

The checkout funnel showed the largest drop-off between the **payment** and **purchase** stages, suggesting that users with strong purchase intent were still failing to complete their orders. In contrast, the SaaS analysis showed that the customer journey often continued even after a failed payment. The dunning workflow recovered a meaningful share of failed subscription payments, highlighting that unlike e-commerce, SaaS products continue optimizing the customer lifecycle well beyond the initial transaction.

**Key takeaway:** Although both domains use funnels to measure progression, the unit of analysis changes from a **session** to an **account lifecycle**. That shift fundamentally changes both the questions being asked and the product decisions that follow.

---

# 2. Retention: Same Metric, Different Meaning

Retention was another analysis where the terminology remained the same, but the underlying business question changed completely.

In the e-commerce dataset, retention was measured as a **behavioural metric**. Weekly cohorts tracked whether customers returned after their first purchase and continued placing orders over time. The retention curve reflected how effectively the product encouraged repeat engagement, making the primary question: **"Do customers come back?"**

The SaaS dataset used the same term **retention**but measured recurring revenue rather than customer activity. Gross Revenue Retention (GRR) evaluated how much recurring revenue was retained after accounting for churn and contraction, while Net Revenue Retention (NRR) also included revenue gained through customer expansion. Instead of asking whether customers returned, the focus shifted to **whether existing accounts continued generating sustainable revenue over time.**

The weekly retention analysis showed the expected decline in repeat customer behaviour across cohorts, reinforcing the importance of lifecycle engagement in e-commerce. In contrast, the SaaS analyses demonstrated that retaining customers is only part of the story. The expansion revenue analysis revealed that **seat additions** contributed the largest share of expansion MRR, followed by plan upgrades and add-ons, illustrating how existing accounts can continue generating revenue long after initial conversion.

This distinction fundamentally changes how growth is achieved. In e-commerce, retained customers generate value by returning to purchase again. In SaaS, retained customers can increase revenue without acquiring a single new account, making expansion an integral part of long-term growth.

**Key takeaway:** Retention is not a universal metric. In B2C, it measures continued customer behaviour. In SaaS, it measures the stability and growth of recurring revenue.

---

# 3. Activation vs. Trial Conversion: Defining the First Moment of Value

While funnels and retention describe how customers progress over time, both businesses also rely on an earlier milestone: identifying when a new user begins to derive meaningful value from the product.

At first glance, activation and trial conversion appear similar. Both measure progress beyond acquisition and answer the question, _"Has this new user successfully moved beyond simply signing up?"_ However, each business defines that success differently.

In the e-commerce dataset, activation measured whether new customers performed a meaningful shopping action within seven days of signup, making it a behavioural indicator of early engagement. In the SaaS dataset, the equivalent milestone was trial conversion, where success depended on accounts becoming paying customers rather than simply engaging with the product.

Although both metrics capture early customer success, one signals initial product engagement while the other marks the beginning of a recurring revenue relationship. This distinction also influences product decisions. Improving activation in e-commerce focuses on reducing friction during discovery and checkout, whereas improving trial conversion requires demonstrating product value, refining onboarding, and encouraging upgrades.

Ultimately, this comparison reinforced an important lesson for me: similar metrics can represent entirely different business objectives. Before measuring any KPI, it is essential to understand **what "value" means for that particular product and business model.**

**Key takeaway:** Activation and trial conversion both measure early customer success, but one captures the beginning of user engagement, while the other marks the beginning of a long-term commercial relationship.

---

# 4. Beyond the Metrics: What Stayed the Same

Despite the differences between the two businesses, one aspect of the project remained remarkably consistent: the analytical process. Whether I was analysing checkout abandonment or Net Revenue Retention, the first step was never writing SQL, it was defining the metric precisely.

Every analysis began by defining the metric before writing SQL. Clarifying the unit of analysis, success criteria, and reporting window proved just as important as the query itself. This was particularly evident when handling inconsistent signup timestamps in the e-commerce dataset and applying reporting cutoffs and revenue classifications in the SaaS analyses.

Only after these assumptions were clear did the SQL become straightforward. Across both datasets, the same analytical building blocks appeared repeatedly, Common Table Expressions (CTEs) to structure complex logic, window functions for cohort and lifecycle analyses, conditional aggregation for conversion metrics, and joins to connect events, customers, subscriptions, and payments. Although the schemas differed, the analytical workflow remained largely unchanged.

Perhaps the biggest lesson was that SQL is only one part of product analytics. A technically correct query has little value if the underlying business metric is poorly defined. Understanding the product context, validating assumptions against the data, and documenting limitations proved just as important as writing efficient SQL.

**Key takeaway:** The SQL techniques changed very little across the two projects. What changed was the business context that gave those queries meaning.

---

# 5. Questions I'd Clarify Before Writing SQL

If someone handed me either of these datasets today and asked me to calculate a metric, my first instinct would be clarifying the business question behind the request.

Throughout the project, I realised that metrics only make sense when their underlying assumptions are explicit. Before measuring conversion or retention, I'd first clarify the unit of analysis, the definition of success, and any business rules or reporting windows that shape the metric.

The project also reinforced the importance of validating the data before analysing it. In the e-commerce dataset, inconsistent timestamps required careful handling to avoid drawing incorrect conclusions about customer behaviour. In the SaaS dataset, understanding how subscription events affected Monthly Recurring Revenue was just as important as writing the aggregation itself. These weren't SQL problems, they were business definition and data quality problems.

Perhaps the biggest shift in my thinking was recognising that SQL is only the final step in the analytical process. The more important work often happens beforehand: defining metrics, understanding the data model, validating assumptions, and ensuring that the numbers genuinely answer the business question being asked.

**Key takeaway:** Good SQL produces numbers. Good analytics starts by ensuring those numbers represent the right business question.

---

# Closing Thoughts

This project showed me that product analytics is less about learning different SQL techniques and more about adapting the same analytical framework to different business models. While the e-commerce analyses focused on customer behaviour and purchasing journeys, the SaaS analyses emphasised recurring revenue, retention, and account expansion. The SQL changed very little; the business questions changed completely.

I found myself particularly drawn to the B2C analyses because the connection between user behaviour and product decisions felt immediate and intuitive. At the same time, working through the SaaS dataset gave me a much stronger appreciation for subscription economics and the importance of looking beyond acquisition to understand retention, expansion, and sustainable growth.

If I were extending this project further, I would explore segmentation by acquisition channel, customer type, or pricing plan to understand how different user groups move through these journeys. Comparing these patterns across segments could uncover more targeted opportunities for improving conversion, retention, and long-term customer value.

Ultimately, the biggest takeaway from this project wasn't learning a new SQL technique, it was learning that the same metric can mean very different things depending on the business context. As an analyst, understanding that context is just as important as writing the query itself.
