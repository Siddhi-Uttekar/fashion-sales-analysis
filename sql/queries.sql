-- Fashion Intelligence Platform — Business Queries
-- Dataset: Global Fashion Retail Sales (stores, products, transactions, customers)
-- ~18 queries covering: joins, aggregation, CASE bucketing, CTEs, window functions, subqueries.

------------------------------------------------------------
-- 0. SANITY CHECK — confirm row counts after import
------------------------------------------------------------
SELECT 'stores' AS table_name, COUNT(*) FROM stores
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'customers', COUNT(*) FROM customers;

-- Row counts after import (for reference — see docs/progress-log.md):
-- stores: 35 · products: 17,940 · customers: 1,643,306 · transactions: 6,416,827


-- Clean up untranslated country name once, before any country-level query
UPDATE stores SET country = 'China' WHERE country = '中国';

------------------------------------------------------------
-- 0b. CURRENCY FIX — centralized as a real column, not repeated per-query
------------------------------------------------------------
-- Originally this project repeated the same CASE WHEN currency-conversion
-- block inline in every revenue query. On review, 3 queries (top
-- sub-categories, average order value, discount bands) were found to be
-- MISSING that conversion entirely — a real bug, caught late. Fix: add a
-- persistent column once, the same way Invoice Total USD was added as a
-- DAX column in Power BI, so the conversion can never be silently skipped
-- again. All revenue figures below use USD (fixed snapshot rates:
-- USD 1.0, EUR 1.08, GBP 1.27, CNY 0.14 — multiplier = 1 ÷ how many units
-- of that currency equal 1 USD, e.g. INR would be 1/83 ≈ 0.012).

ALTER TABLE transactions ADD COLUMN invoice_total_usd NUMERIC;

UPDATE transactions
SET invoice_total_usd = CASE currency
    WHEN 'USD' THEN invoice_total
    WHEN 'EUR' THEN invoice_total * 1.08
    WHEN 'GBP' THEN invoice_total * 1.27
    WHEN 'CNY' THEN invoice_total * 0.14
    ELSE invoice_total
END;

------------------------------------------------------------
-- 1. REVENUE & CATEGORY
------------------------------------------------------------

-- Q: What is total revenue by category, in mixed/raw currency?
-- (WRONG on its own — kept to show the before/after of the currency fix)
SELECT
    p.category,
    SUM(t.invoice_total) AS total_revenue_raw_mixed_currency
FROM transactions t
JOIN products p ON p.product_id = t.product_id
GROUP BY p.category
ORDER BY total_revenue_raw_mixed_currency DESC;

--Raw : Feminine ~$717M, Masculine ~$679M, Children ~$166M

-- Q: What is total revenue by category, correctly converted to USD?
SELECT
    p.category,
    SUM(t.invoice_total_usd) AS revenue_usd
FROM transactions t
JOIN products p ON p.product_id = t.product_id
GROUP BY p.category
ORDER BY revenue_usd DESC;

--Corrected (documented): Feminine ~$293M, Masculine ~$245M, Children ~$64M
--multiplier = 1 ÷ (how many units of that currency equal 1 USD) eg INR is 1/83 ≈ 0.012


-- Q: Top 10 sub-categories by revenue and units sold
SELECT
    p.sub_category,
    SUM(t.invoice_total_usd) AS revenue_usd,
    SUM(t.quantity) AS units_sold
FROM transactions t
JOIN products p ON p.product_id = t.product_id
GROUP BY p.sub_category
ORDER BY revenue_usd DESC
LIMIT 10;

------------------------------------------------------------
-- 2. GEOGRAPHY
------------------------------------------------------------

-- Q: Revenue by country, currency-corrected — is China really dominant, or a currency artifact?
SELECT
    s.country,
    SUM(t.invoice_total_usd) AS revenue_usd
FROM transactions t
JOIN stores s ON s.store_id = t.store_id
GROUP BY s.country
ORDER BY revenue_usd DESC;

-- Q: Top 10 individual stores by revenue — explains part of China's country-level performance
SELECT
    s.store_name, s.country,
    SUM(t.invoice_total_usd) AS revenue_usd
FROM transactions t
JOIN stores s ON s.store_id = t.store_id
GROUP BY s.store_name, s.country
ORDER BY revenue_usd DESC
LIMIT 10;

------------------------------------------------------------
-- 3. TIME TRENDS (window function)
------------------------------------------------------------

-- Q: What is month-over-month revenue growth? (uses LAG() — a window function,
-- the one SQL technique genuinely new relative to typical backend/CRUD SQL)
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', date) AS month,
        SUM(invoice_total_usd) AS revenue_usd
    FROM transactions
    GROUP BY 1
)
SELECT
    month,
    revenue_usd,
    LAG(revenue_usd) OVER (ORDER BY month) AS prev_month,
    ROUND(
        100.0 * (revenue_usd - LAG(revenue_usd) OVER (ORDER BY month))
        / NULLIF(LAG(revenue_usd) OVER (ORDER BY month), 0), 2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

------------------------------------------------------------
-- 4. CUSTOMERS
------------------------------------------------------------

-- Q: What % of customers who ordered at least once came back for a repeat order?
-- (Full-dataset version — an earlier Power BI dashboard's 7.98% was based on a
-- ~100k-row sample and understated this; this is the trustworthy figure.)
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

-- Q: Revenue by gender
SELECT
    c.gender,
    SUM(t.invoice_total_usd) AS revenue_usd
FROM transactions t
JOIN customers c ON c.customer_id = t.customer_id
GROUP BY c.gender
ORDER BY revenue_usd DESC;

-- Q: Average order value (subquery collapses line items to one row per order first)
SELECT AVG(order_total) AS avg_order_value
FROM (
    SELECT invoice_id, SUM(invoice_total_usd) AS order_total
    FROM transactions
    GROUP BY invoice_id
) order_totals;

------------------------------------------------------------
-- 5. DISCOUNTS & MARKETING
------------------------------------------------------------

-- Q: How does discount level affect revenue and units sold?
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.20 THEN '11-20%'
        WHEN discount <= 0.30 THEN '21-30%'
        ELSE '31%+'
    END AS discount_band,
    SUM(invoice_total_usd) AS revenue_usd,
    SUM(quantity) AS units_sold
FROM transactions
GROUP BY 1
ORDER BY revenue_usd DESC;

------------------------------------------------------------
-- Total: ~18 queries across category/geography/time/customer/discount analysis,
-- covering JOINs, GROUP BY aggregation, CASE bucketing, CTEs, window functions,
-- FILTER, and subqueries. Scoped down from an original 40-50 target — prioritized
-- technique variety over query count (see docs/progress-log.md for the reasoning).
--
-- NOTE: currency conversion was originally repeated inline per-query, which
-- caused 3 queries to silently miss the fix during a later addition. Refactored
-- into a persistent invoice_total_usd column (see section 0b) so the conversion
-- can't be accidentally skipped again — the same pattern used for the
-- Invoice Total USD column in the Power BI model.
------------------------------------------------------------