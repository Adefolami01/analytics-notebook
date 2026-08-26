# Project 2: E-Commerce Monthly Business Trends Analysis

## Overview

This project uses SQL to analyze monthly business performance for a real-world e-commerce marketplace, using the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle. The dataset contains approximately 100,000 orders placed on the Olist platform between September 2016 and October 2018, spanning multiple sellers, product categories, and customers across Brazil.

The objective was to approach this dataset the way an analyst would when asked to report on "how the business is trending" — starting from raw transactional data and working toward a set of clear, decision-useful insights: revenue growth over time, the product categories driving that growth, how customers pay, and how well the platform retains customers after a first purchase.

This project builds directly on SQL fundamentals covered earlier in this learning path (joins, subqueries, aggregate functions) and applies window functions (`RANK()`, `LAG()`) to solve problems that plain `GROUP BY` aggregation can't handle on its own — ranking within groups and comparing a row to the row before it.

## Business Context

Olist is a Brazilian marketplace that connects small businesses to major online sales channels, similar in concept to Shopify or Amazon Marketplace. The dataset reflects real seller and customer behavior, including natural data quality issues (multiple order statuses, inconsistent category naming, and skewed early-period data) rather than a cleaned, classroom-style sample. That made this a useful exercise in handling imperfect data, not just writing queries against a tidy schema.

## Data Model

The analysis draws on six relational tables from the Olist dataset:

| Table | Purpose |
|---|---|
| `orders` | One row per order, including status and key timestamps (purchase, delivery) |
| `order_items` | Line-item level detail: product, seller, price, freight cost per order |
| `order_payments` | Payment method and value per order (an order can have multiple payment records) |
| `customers` | Customer identifiers and location |
| `products` | Product-level metadata, including category (in Portuguese) |
| `category_translation` | Maps Portuguese category names to their English equivalents |

All five analyses join across these tables and filter to `order_status = 'delivered'`, so the results reflect completed transactions rather than cancelled, unavailable, or still-processing orders.

## Tools & Environment

- **Database engine:** SQLite, run in-browser via [SQLite Online](https://sqliteonline.com)
- **Techniques applied:** multi-table JOINs, Common Table Expressions (CTEs), `GROUP BY` aggregation, and window functions (`RANK() OVER (PARTITION BY ...)`, `LAG() OVER (ORDER BY ...)`)
- **Output handling:** each query's results were exported to CSV directly from SQLite Online for reproducibility, rather than relying on screenshots

## Methodology

For each business question below, the same general approach was followed:
1. Identify the tables and join keys needed to answer the question.
2. Write an initial query, using `PRAGMA table_info()` or `sqlite_master` lookups where needed to confirm actual column names (several were truncated on CSV import — see **Data Quality Notes** below).
3. Where a question required comparing rows to each other (previous month, rank within a month), wrap the base aggregation in a CTE and apply a window function.
4. Validate results for internal consistency (e.g. confirming the first month in a growth calculation correctly returns `NULL` rather than a false percentage).

## Queries & Findings

### 1. Monthly Revenue Trend
**Question:** How has total revenue and order volume changed month over month?

```sql
SELECT 
  strftime('%Y-%m', o.order_purchase_t) AS month,
  SUM(oi.price) AS total_revenue,
  COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;
```

**Finding:** Revenue grew from a negligible base in September 2016 (a single order) to sustained monthly revenue above $900,000 by late 2017 and into 2018. Order volume followed the same trajectory, climbing from a few hundred orders per month in early 2017 to over 7,000 per month by mid-2018. This confirms consistent, compounding platform growth rather than a one-time spike.

[Query](./queries.sql#query-1) · [Results](./results/query1_revenue_trend.csv)

### 2. Month-over-Month Revenue Growth %
**Question:** What is the rate of growth (or decline) between consecutive months?

```sql
WITH monthly AS (
  SELECT 
    strftime('%Y-%m', o.order_purchase_t) AS month,
    SUM(oi.price) AS total_revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY month
)
SELECT 
  month,
  total_revenue,
  LAG(total_revenue) OVER (ORDER BY month) AS prev_month_revenue,
  ROUND(
    (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) * 100.0 
    / LAG(total_revenue) OVER (ORDER BY month), 2
  ) AS growth_pct
FROM monthly
ORDER BY month;
```

**Finding:** The earliest months show extreme, statistically meaningless percentage swings (as high as +1,025,573%) — a direct result of the tiny order volume in the platform's launch period, where even a small dollar increase produces an enormous percentage change. From 2017 onward, once monthly order volume is in the hundreds/thousands, growth rates settle into a more realistic and interpretable range (typically -15% to +55% month over month), with occasional seasonal dips (e.g. December 2017: -26.5%).

**Analytical note:** This is a useful caution for any growth-rate analysis — percentage change is only meaningful once the underlying sample size is large enough that small absolute changes don't distort the ratio.

[Query](./queries.sql#query-2) · [Results](./results/query2_growth_results.csv)

### 3. Top 3 Product Categories by Monthly Revenue
**Question:** Which product categories are generating the most revenue each month, and how does that mix shift over time?

```sql
WITH monthly_category AS (
  SELECT 
    strftime('%Y-%m', o.order_purchase_t) AS month,
    ct.product_category AS category,
    ROUND(SUM(oi.price), 2) AS category_revenue
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN products p ON oi.product_id = p.product_id
  JOIN category_translation ct ON p.product_category = ct.product_category
  WHERE o.order_status = 'delivered'
  GROUP BY month, category
),
ranked AS (
  SELECT 
    month, category, category_revenue,
    RANK() OVER (PARTITION BY month ORDER BY category_revenue DESC) AS category_rank
  FROM monthly_category
)
SELECT * FROM ranked WHERE category_rank <= 3 ORDER BY month, category_rank;
```

**Finding:** `beleza_saude` (health & beauty) is the single most consistent top-revenue category across nearly the entire dataset, frequently holding the #1 spot from early 2017 onward. `moveis_decoracao` (furniture & home decor) is an early leader and remains a consistent top-3 category. As the platform scales through 2017, additional categories such as `informatica_acessorios` (computer accessories), `cama_mesa_banho` (bed, bath & table), and `relogios_presentes` (watches & gifts) enter the top 3 in different months, suggesting a broadening product mix rather than reliance on a single category.

[Query](./queries.sql#query-3) · [Results](./results/query3_top_categories.csv)

### 4. Payment Method Trends
**Question:** How do customers pay, and has that changed over time?

```sql
SELECT 
  strftime('%Y-%m', o.order_purchase_t) AS month,
  op.payment_type,
  COUNT(*) AS num_payments,
  ROUND(SUM(op.payment_value), 2) AS total_value
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY month, op.payment_type
ORDER BY month, total_value DESC;
```

**Finding:** Credit card is the dominant payment method in every month observed, typically accounting for roughly 70-80% of both transaction count and total value. Boleto (a common Brazilian cash-voucher payment slip) is a consistent second, while debit card and voucher payments remain a small minority throughout. This pattern is stable across the full date range, indicating no meaningful shift in customer payment preference as the platform grew.

[Query](./queries.sql#query-4) · [Results](./results/query4_payment_methods.csv)

### 5. New vs. Returning Customers
**Question:** What proportion of monthly orders come from repeat customers, and is that improving over time?

```sql
WITH customer_orders AS (
  SELECT 
    c.customer_unique,
    strftime('%Y-%m', o.order_purchase_t) AS month,
    o.order_id,
    RANK() OVER (PARTITION BY c.customer_unique ORDER BY o.order_purchase_t) AS order_rank
  FROM orders o
  JOIN customers c ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
)
SELECT 
  month,
  SUM(CASE WHEN order_rank = 1 THEN 1 ELSE 0 END) AS new_customers,
  SUM(CASE WHEN order_rank > 1 THEN 1 ELSE 0 END) AS returning_customers
FROM customer_orders
GROUP BY month
ORDER BY month;
```

**Finding:** This is the most significant finding of the analysis. Across every month in the dataset, the overwhelming majority of orders come from first-time customers, while returning customers make up only a small single-digit percentage of monthly volume — for example, March 2017 shows 2,509 new customers against just 37 returning customers (roughly 1.5%). This ratio holds consistently even as total order volume scales into the thousands per month, indicating that Olist's growth during this period was driven almost entirely by new customer acquisition rather than repeat purchase behavior.

[Query](./queries.sql#query-5) · [Results](./results/query5_customer_retention.csv)

## Key Takeaways & Recommendations

1. **Revenue growth is real and sustained**, not a short-term spike — the platform scaled consistently from late 2016 through 2018 across both order volume and revenue.
2. **Health & beauty and home/furniture categories are the platform's most reliable revenue drivers** and warrant continued marketing and inventory investment.
3. **Credit card is the default payment rail** for this customer base; payment options and checkout flow should be optimized around credit card first, with boleto as a well-supported secondary option.
4. **Customer retention is the clearest opportunity for improvement.** With returning customers consistently under ~5% of monthly volume, a targeted retention strategy (email remarketing, loyalty incentives, post-purchase follow-up) could meaningfully improve unit economics without requiring additional acquisition spend.

## Data Quality Notes

- SQLite Online's CSV import truncates some long column names to a fixed character limit — for example, `order_purchase_timestamp` was imported as `order_purchase_t`, and `product_category_name` as `product_category`. Queries in this repo reflect the actual (truncated) column names as they exist in the imported tables; this is noted here for anyone attempting to reproduce the analysis against a differently-imported copy of the dataset.
- All queries filter to `order_status = 'delivered'` to ensure the analysis reflects completed transactions only, excluding cancelled or in-progress orders.
- Early months (September–December 2016) have very low order volume and should be interpreted as platform launch data rather than representative business performance.

## Skills Demonstrated

- Multi-table JOINs across a normalized relational schema
- Common Table Expressions (CTEs) for multi-step query logic
- Window functions: `RANK() OVER (PARTITION BY ...)` for within-group ranking, `LAG() OVER (ORDER BY ...)` for period-over-period comparison
- Debugging real SQL errors (window function alias scoping, truncated column names) using `PRAGMA table_info()` and `sqlite_master` schema inspection
- Translating raw query output into business-relevant, decision-useful findings

## Repository Structure

```
project-2-ecommerce-trends/
├── README.md              # This write-up
├── queries.sql             # All 5 queries, in order
└── results/
    ├── query1_revenue_trend.csv
    ├── query2_growth_results.csv
    ├── query3_top_categories.csv
    ├── query4_payment_methods.csv
    └── query5_customer_retention.csv
```

## Data Source

Olist Brazilian E-Commerce Public Dataset, available on [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
