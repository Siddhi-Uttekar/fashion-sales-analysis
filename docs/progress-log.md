# Progress Log — Session 1

A running log of what's been done, how, and what's left — update this after
each work session rather than trying to reconstruct it later.

## Dataset decision
Evaluated five Kaggle candidates against the Phase 1 checklist (transactions,
date, category, city/geography, customer, returns, 50k-500k rows):
- **Fashion Retail Sales** — rejected: no category or city columns
- **Global Fashion Retail Sales** — chosen: only one with category, geography,
  customer demographics, and pricing/discount together, at real transaction
  grain. Trade-off accepted: 6.4M rows (over target) and multi-currency data
  (added real complexity), both manageable.
- **Zara EDA**, **Myntra Products** — rejected: product catalogs, not
  transaction-level sales data (no order_id, no customer, no real date)
- **Snitch Fashion Sales** — noted as a possible future side-exercise for
  deliberately messy-data cleaning practice, not used as the primary dataset

Confirmed the dataset's real structure directly from the files (not assumed):
`transactions.csv` (line-item sales), `products.csv` (category/sub-category),
`stores.csv` (country/city), `customers.csv` (demographics) — linked by
Product ID and Store ID.

## What was built today

### 1. Power BI — three dashboard pages
Learned Power BI from zero using a tiny hand-built dataset first (Data view /
Model view / Report view, drag-and-drop aggregation, one DAX column), then
applied the same patterns to the real dataset.

- Imported all four files; `transactions.csv` (767MB) sampled down to ~100k
  rows via Power Query's "Remove Alternate Rows" (keep 1 of every 40) after
  an initial "Keep Top Rows" sample proved biased (all rows from one time
  period, which showed as a flat single-point line chart).
- **Sales page:** Category table + bar chart, Country table, Revenue trend
  line (drilled to Year+Month via "Expand to next level," since drilling
  through the default hierarchy collapses years together).
- **Customers page:** Gender, Age Group (via a DAX `SWITCH` bucketing column
  from Date of Birth), Customer Type (New/Returning, via an `Order Count`
  column and `IF`), Repeat Purchase Rate card (a DAX measure).
- **Marketing page:** Discount Band (bucketed via DAX, since raw discount
  values didn't summarize cleanly as a category), Payment Method.
- Fixed a garbled-text (mojibake) import issue on `customers.csv` by
  correcting the Power Query `Encoding` parameter from `1252` to `65001`
  (UTF-8) in the Advanced Editor.
- Map visual hit a "Map visuals are disabled" security setting; worked around
  it with a plain table instead of enabling the setting.

### 2. Two real analysis mistakes — found and corrected
- **Currency bug:** `Invoice Total` was being summed raw across USD/EUR/GBP/
  CNY. This made China look like ~74% of total revenue. Added an
  `Invoice Total USD` DAX column (fixed snapshot conversion rates) and
  re-checked — China and US are actually roughly tied, each far ahead of
  Europe on a like-for-like basis.
- **Sampling bug:** `Repeat Purchase Rate` measure initially compared against
  all 1.64M rows in `customers`, most of which never appear in the ~100k-row
  transaction sample — understating the rate to 0.7%. Restricted the
  denominator (via a Power Query merge/inner join) to only customers present
  in transactions, correcting it to 7.98% — still later found to be a
  sample-size artifact once cross-checked against the full dataset in SQL
  (see below).

### 3. PostgreSQL — full dataset, no sampling
- Installed PostgreSQL 18 + pgAdmin; learned pgAdmin's Query Tool and CSV
  import tool (hit and fixed a classic "header row read as data" error by
  toggling the importer's Header setting on).
- Created `fashion_db` with 4 tables — `stores`, `products`, `transactions`,
  `customers` — matching the real file structure, and imported all four CSVs
  **in full** (Postgres doesn't need the sampling Power BI required):
  `stores`: 35, `products`: 17,940, `customers`: 1,643,306,
  `transactions`: 6,416,827 rows.
- Wrote and ran ~10 real business queries (see `sql/queries.sql`): revenue by
  category (raw vs. currency-corrected), top sub-categories, revenue by
  country, repeat-customer rate, discount-band impact.
- **Key discovery:** the full-dataset repeat rate is **75.08%**, far above
  the Power BI sample's 7.98% — confirming the sample understated repeat
  purchases due to sparse coverage of a 1.64M-customer base.

## Insights captured (full detail in `docs/insights.md`)
1. Feminine (~$293M) and Masculine (~$245M) categories lead; Children's
   (~$64M) trails ~4x behind, currency-corrected.
2. Coats and Blazers / Pants and Jeans lead sub-categories by revenue;
   Accessories is the standout high-volume, lower-price line.
3. China and United States are essentially tied at the top of revenue by
   country (~$160M each, currency-corrected) — a genuine per-store gap
   over Europe, not a store-count or currency artifact.
4. True repeat purchase rate is 75.08% (full dataset) — the sampled
   dashboard figure of 7.98% should not be reported as-is.
5. Full-price sales drive ~74% of revenue; deep (31%+) discounts move
   more volume than moderate discounts, suggesting they're used for
   clearance rather than routine pricing.
6. Credit card accounts for ~80% of revenue vs. ~20% cash.

## Next steps remaining (against the original 12-phase plan)
- [ ] **Phase 4 (SQL):** revised target — 20-25 total well-chosen queries
      (not the original 40-50), prioritizing technique variety over count.
      Still missing: a window-function query (RANK/LAG for MoM growth —
      the one technique not used yet), monthly/seasonal trend
      (currency-corrected), a gender/age breakdown (join to customers),
      employee/store performance. ~5-8 queries needed, not ~30.
- [ ] **Phase 5 (Python):** cleaning + analysis notebooks against the real
      dataset (templates already exist in `notebooks/`, not yet run against
      real data)
- [ ] **Phase 6 (KPIs as SQL views):** `sql/views.sql` needs updating to
      match the real schema (currently still the generic template)
- [ ] **Phase 7 (Power BI):** optionally add Executive Overview and/or
      Inventory pages (Inventory needs adaptation — this dataset has no
      returns table)
- [ ] **Phase 9 (Forecasting):** not started — Prophet/regression on the
      monthly revenue trend
- [ ] **Phase 10 (Recommendation engine):** not started
- [ ] **Phase 11 (Portfolio site + backend):** not started — `backend/main.py`
      skeleton exists but still points at placeholder schema/views
- [ ] **Phase 12 (Documentation):** `architecture.md` and `business_problem.md`
      still have placeholder/generic content and need updating to reflect
      the real dataset and decisions made today
- [ ] Screenshot the three completed Power BI pages into `docs/screenshots/`
      (not yet done)

**Rough completion: ~30-35% of the full project scope.**

## Decisions log
- Revised SQL query target from the original plan's 40-50 down to
  20-25 — the number was a rough heuristic, not a hard requirement.
  Prioritize technique variety (joins, window functions, CTEs, aggregation,
  currency/bucketing logic) over hitting a round count.


## Scope cut — 2-day completion target (revised)
Goal reframed: this project exists to show hirers (resume centered on
full-stack + GenAI) basic data-analytics competency as a fresh grad — not
to be a portfolio centerpiece. Cutting scope hard accordingly:

**Cut entirely:** recommendation engine (Phase 10), FastAPI backend +
React portfolio site (Phase 11 — redundant given existing full-stack
projects elsewhere), Executive Overview / Inventory Power BI pages,
Prophet (swapped for a simple sklearn linear regression baseline only).

**Remaining plan:**
- Day 1: finish country-revenue Python script, 6-8 more SQL queries
  (window function for MoM growth, gender/age breakdown, store
  performance, average order value — target ~18-20 total, not 40-50),
  screenshot the 3 Power BI pages, finalize insights.md
- Day 2: one simple linear-regression forecast in Python, write the
  final README (dataset, findings, the currency + sampling bugs caught
  and fixed as the headline story), push to GitHub

Estimated remaining effort: ~4-5 hours total, not the original full
12-phase scope.