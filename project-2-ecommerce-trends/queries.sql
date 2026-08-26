-- Query 1: Monthly revenue trend
  SELECT 
  strftime('%Y-%m', o.order_purchase_timestamp) AS month,
  SUM(oi.price) AS total_revenue,
  COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;
-- Note: SQLite Online truncated order_purchase_timestamp to order_purchase_t on import





-- Query 2: Month-over-month revenue growth %
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
    / LAG(total_revenue) OVER (ORDER BY month), 
    2
  ) AS growth_pct
FROM monthly
ORDER BY month;



-- Query 3: Top 3 product categories by monthly revenue
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
    month,
    category,
    category_revenue,
    RANK() OVER (PARTITION BY month ORDER BY category_revenue DESC) AS category_rank
  FROM monthly_category
)
SELECT *
FROM ranked
WHERE category_rank <= 3
ORDER BY month, category_rank;


-- Query 4: Payment method trends by month
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


-- Query 5: New vs returning customers by month
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