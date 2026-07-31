-- Fashion Intelligence Platform — KPI Views
-- Pre-aggregated, currency-corrected views matching the real schema.
-- These centralize the currency conversion logic in one place instead
-- of repeating the CASE WHEN block in every query (the currency bug
-- documented in docs/insights.md happened partly because this
-- conversion wasn't centralized from the start — a lesson worth
-- stating explicitly if asked in an interview).

CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT
    DATE_TRUNC('month', date) AS month,
    SUM(
        CASE currency
            WHEN 'USD' THEN invoice_total
            WHEN 'EUR' THEN invoice_total * 1.08
            WHEN 'GBP' THEN invoice_total * 1.27
            WHEN 'CNY' THEN invoice_total * 0.14
            ELSE invoice_total
        END
    ) AS revenue_usd,
    COUNT(DISTINCT invoice_id) AS orders
FROM transactions
GROUP BY 1;

CREATE OR REPLACE VIEW vw_category_revenue AS
SELECT
    p.category,
    p.sub_category,
    SUM(
        CASE t.currency
            WHEN 'USD' THEN t.invoice_total
            WHEN 'EUR' THEN t.invoice_total * 1.08
            WHEN 'GBP' THEN t.invoice_total * 1.27
            WHEN 'CNY' THEN t.invoice_total * 0.14
            ELSE t.invoice_total
        END
    ) AS revenue_usd,
    SUM(t.quantity) AS units_sold
FROM transactions t
JOIN products p ON p.product_id = t.product_id
GROUP BY p.category, p.sub_category;

CREATE OR REPLACE VIEW vw_country_revenue AS
SELECT
    s.country,
    SUM(
        CASE t.currency
            WHEN 'USD' THEN t.invoice_total
            WHEN 'EUR' THEN t.invoice_total * 1.08
            WHEN 'GBP' THEN t.invoice_total * 1.27
            WHEN 'CNY' THEN t.invoice_total * 0.14
            ELSE t.invoice_total
        END
    ) AS revenue_usd
FROM transactions t
JOIN stores s ON s.store_id = t.store_id
GROUP BY s.country;

CREATE OR REPLACE VIEW vw_customer_repeat_rate AS
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT invoice_id) AS order_count
    FROM transactions
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    COUNT(*) AS total_customers_with_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_orders;