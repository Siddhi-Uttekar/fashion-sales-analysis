# Fashion Intelligence Platform — Step-by-Step Build Guide

**Who this is for:** you already know full-stack dev (React/Next.js/Node/FastAPI/PostgreSQL) and have hands-on GenAI experience (LangChain, FAISS, RAG). You are new to data analytics (SQL for analysis, Power BI, statistical/ML forecasting). This guide is sequenced so you spend almost no time on things you already know and most of your time on the genuinely new skills: **analytical SQL, BI dashboarding, and time-series forecasting.**

Each phase has: what to learn → why → how long → deliverable → code/architecture.

---

## Phase 0 — Learn the Basics (aim for 4–6 days, not a week — you have a head start)

### 0.1 SQL for analysts (this is the real new skill — spend most of your time here)
You know CRUD SQL from backend work. Analytical SQL is different: aggregation, window functions, and business-question framing.

Learn, in this order:
1. `GROUP BY` + `HAVING` (aggregating, then filtering aggregates)
2. `JOIN` types (`INNER`, `LEFT`, and when each matters for "did NOT happen" questions like "customers with no orders")
3. `CASE WHEN` (bucketing — e.g., turning ages into age groups)
4. Window functions — **this is the one most engineers haven't touched**:
   - `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`
   - `RANK()`, `DENSE_RANK()`
   - `SUM(...) OVER (PARTITION BY ... ORDER BY ...)` for running totals
   - `LAG()`/`LEAD()` for month-over-month comparisons

Practice resource: [Mode Analytics SQL Tutorial](https://mode.com/sql-tutorial/) (free, business-question framed — closest to what you'll actually do) or [SQLZoo](https://sqlzoo.net/).

**Deliverable for Phase 0.1:** solve 10 window-function practice problems and save them in `sql/practice.sql`.

### 0.2 Python for analysis
You know Python. You need three libraries, not the language:
- **Pandas**: `groupby`, `merge`, `pivot_table`, `resample` (for time-series), `.apply()`
- **NumPy**: mostly used under the hood by Pandas — you won't write much raw NumPy
- **Matplotlib/Seaborn**: enough to make a line chart, bar chart, and heatmap

Skip a course — just do the [Pandas 10-minute guide](https://pandas.pydata.org/docs/user_guide/10min.html) then learn `groupby`/`pivot_table` by using them on Phase 1's dataset.

### 0.3 Power BI (net-new tool for you)
This is the one tool in your stack you've never touched. Budget 2 focused days:
- Import data (CSV or a live PostgreSQL connection via Power BI's built-in connector)
- Data model: relationships between tables (this maps directly to your SQL foreign-key intuition)
- **DAX basics**: `CALCULATE()`, `SUM()`, `DIVIDE()`, simple measures — DAX is closer to Excel formulas than to SQL, so don't try to force SQL mental models onto it
- Visuals: cards, bar/line charts, slicers, filters, a matrix table

Resource: [Microsoft's official Power BI Guided Learning](https://learn.microsoft.com/en-us/power-bi/guided-learning/) — free, ~6 hours total, do the "Get Started" and "Model Data" modules.

**Deliverable for Phase 0:** one paragraph in `docs/architecture.md` (already scaffolded below) confirming you can explain: a window function, a Power BI measure, and a JOIN — in your own words.

---

## Phase 1 — Find a Dataset

Search Kaggle for one of:
- "Fashion Retail Sales Dataset"
- "Myntra Dataset"
- "E-commerce Dataset"
- "Retail Sales Dataset"

Target size: **50k–500k rows**. Bigger than that slows down Power BI on a laptop; smaller than that makes your KPIs look thin.

What to check before committing to a dataset:
- Does it have a **date column** (needed for Phase 9 forecasting)?
- Does it have **category/brand/city** columns (needed for the dashboard breakdowns in Phase 7)?
- Is there a **returns flag or returns table** (needed for the return-rate insight in Phase 8's example)?

If one dataset doesn't have everything, it's fine to combine two Kaggle datasets (e.g., a sales dataset + a synthetic returns table) — this is realistic; real analysts rarely get one clean source.

Save the raw file(s) to `data/raw/` (don't commit large CSVs to GitHub — add `data/raw/` to `.gitignore` and instead commit a `data/README.md` explaining where to download it).

---

## Phase 2 — Business Understanding

Before touching code, write down (in `docs/business_problem.md`, scaffolded below) the business questions as if you're a Product/Technology Consultant scoping the project for a client:

- How is the business performing? (revenue, orders, growth trend)
- Can we increase profit? (margin by category, discount impact)
- Why are customers returning products? (return rate by category/size)
- What categories/brands sell best?
- Which cities/regions drive the most revenue?

This step matters more than it looks — it's what separates "I made some charts" from "I scoped and delivered an analytics solution," which is the framing recruiters and interviewers respond to.

---

## Phase 3 — Database Design

Use PostgreSQL (matches your existing stack — you can reuse the same Docker + `psycopg2`/SQLAlchemy patterns you already know from FastAPI work).

### Architecture at this stage
```
CSV (Kaggle)
   │  pandas: clean + reshape
   ▼
PostgreSQL (normalized schema)
   │
   ▼
SQL analysis layer (views + queries)
```

### Suggested schema
A starter `sql/schema.sql` is included in this repo (see `sql/schema.sql`) with these tables:
- `customers` (customer_id, name, gender, age, city_id, signup_date)
- `cities` (city_id, city_name, state)
- `categories` (category_id, category_name)
- `products` (product_id, product_name, category_id, brand, price, cost)
- `orders` (order_id, customer_id, order_date, status)
- `order_items` (order_item_id, order_id, product_id, quantity, unit_price, discount)
- `returns` (return_id, order_item_id, return_date, reason)

Load the Kaggle CSV into a staging table first, then use `INSERT INTO ... SELECT` to populate the normalized tables — this is a realistic ETL pattern worth showing in your documentation.

```sql
-- Example staging pattern
CREATE TABLE staging_sales (
    raw_customer_name TEXT,
    raw_product_name TEXT,
    raw_category TEXT,
    raw_city TEXT,
    order_date DATE,
    quantity INT,
    unit_price NUMERIC,
    discount NUMERIC
);
-- COPY staging_sales FROM '/path/to/kaggle.csv' WITH (FORMAT csv, HEADER true);
```

---

## Phase 4 — SQL Analysis (40–50 business queries)

Write these into `sql/queries.sql`, organized by category. A starter file with ~20 queries across all categories is already in this repo — extend it to 40–50 as you explore your specific dataset. Categories to cover:

1. **Revenue & growth**: monthly revenue, MoM growth %, YoY comparison
2. **Products**: top 10 brands, most profitable products, slow-moving inventory
3. **Customers**: repeat customers, customer lifetime value, new vs. returning
4. **Geography**: top cities/states by revenue
5. **Returns**: return rate by category, return rate by size (if available)
6. **Seasonality**: revenue by month/week to spot festival spikes

Example (this is exactly the kind of window-function query from Phase 0.1 in real use):

```sql
-- Month-over-month revenue growth
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;
```

Push every query to GitHub as you write it — recruiters and interviewers look at commit history, not just the final file.

---

## Phase 5 — Python Analysis

Create three notebooks/scripts (starters included in `notebooks/`):
- `01_data_cleaning.py` — missing values, duplicates, date parsing, outlier detection
- `02_sales_analysis.py` — the KPI calculations from Phase 6, using `groupby`/`pivot_table`
- `03_forecasting.py` — Phase 9's forecasting model

Connect Python directly to PostgreSQL rather than re-reading the CSV, to mirror a real analytics pipeline:

```python
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://user:password@localhost:5432/fashion_db")
orders = pd.read_sql("SELECT * FROM orders", engine)
order_items = pd.read_sql("SELECT * FROM order_items", engine)
```

---

## Phase 6 — KPIs

Calculate these once in Python (or as SQL views — either is fine, but doing both shows range):

| KPI | Formula |
|---|---|
| Revenue | `SUM(quantity * unit_price * (1-discount))` |
| Profit | `Revenue - SUM(quantity * cost)` |
| Average Order Value | `Revenue / COUNT(DISTINCT order_id)` |
| Return Rate | `COUNT(returns) / COUNT(order_items)` |
| Repeat Purchase Rate | `customers with >1 order / total customers` |
| Customer Lifetime Value | `AVG(revenue per customer)` (simple version) |

Save these as a SQL **view** (`sql/views.sql`) so Power BI can pull a clean, pre-aggregated table instead of raw transactional data — this is the correct real-world pattern and worth calling out explicitly in your architecture doc.

---

## Phase 7 — Power BI Dashboard (5 pages)

Connect Power BI directly to your PostgreSQL views from Phase 6. Build:

1. **Executive Overview** — revenue, profit, orders, growth (cards + trend line)
2. **Sales** — top categories/brands, revenue trend, city-wise map or bar chart
3. **Customers** — new vs. returning, demographics, repeat purchase rate, optionally RFM segmentation
4. **Inventory** — fast-movers, dead stock, return rate by product
5. **Marketing** — discount impact on revenue, seasonality, top-selling colors/sizes

Export each page as a screenshot into `docs/screenshots/` for the portfolio site — Power BI dashboards themselves don't embed well in a public portfolio, so screenshots + a short recorded walkthrough (Loom/YouTube unlisted) are the standard workaround.

---

## Phase 8 — Business Insights (this is what makes it a portfolio piece, not a school project)

For every dashboard page, write 2–3 insight statements in `docs/insights.md` that go beyond the chart, e.g.:

> "Women's ethnic wear contributes 28% of revenue but has the highest return rate, suggesting sizing or expectation issues."

Structure each insight as **observation → likely cause → recommended action** — that three-part structure is what a Business Analyst or Technology Consultant is actually being paid for.

---

## Phase 9 — AI Forecasting

Given your GenAI background, this will feel more like "classic ML" than what you're used to — that contrast is worth mentioning in interviews.

Start simple, then add complexity only if you have time:
1. **Baseline**: linear regression on `month_number → revenue` (scikit-learn) — gets you a working forecast fast
2. **Better**: Facebook Prophet — handles seasonality (festival spikes) automatically, minimal tuning
3. **Stretch**: XGBoost with engineered lag features, if you want to show ML depth

```python
from prophet import Prophet

df = monthly_revenue.rename(columns={"month": "ds", "revenue": "y"})
model = Prophet(yearly_seasonality=True)
model.fit(df)
future = model.make_future_dataframe(periods=3, freq="M")
forecast = model.predict(future)
```

Display the forecast as a line chart with a shaded confidence interval (Matplotlib `fill_between`, or embed directly in the portfolio site via Recharts if you export forecast points as JSON).

---

## Phase 10 — Recommendation Engine

Simple, explainable version — cosine similarity over a product co-purchase matrix:

```python
from sklearn.metrics.pairwise import cosine_similarity
import pandas as pd

basket = pd.crosstab(order_items["order_id"], order_items["product_id"])
similarity = pd.DataFrame(
    cosine_similarity(basket.T),
    index=basket.columns, columns=basket.columns
)

def recommend(product_id, n=5):
    return similarity[product_id].sort_values(ascending=False)[1:n+1]
```

This is a good place to note in your docs that you *chose* the simple, explainable approach over a black-box collaborative-filtering library — that's a real engineering trade-off worth articulating.

---

## Phase 11 — Portfolio Website

Your strongest phase — this is just your existing React/Next.js stack. A minimal FastAPI backend to serve the KPIs and forecast as JSON is scaffolded in `backend/main.py`. Structure the site around a narrative, not a gallery:

1. Business problem
2. Your approach (architecture diagram)
3. Technologies used
4. Key insights (pull straight from `docs/insights.md`)
5. What decisions the dashboard enables
6. Links: GitHub repo, SQL queries, live demo, dashboard screenshots

---

## Phase 12 — Documentation

This repo is already scaffolded with the structure below. Fill in each file as you complete the corresponding phase — don't leave it all for the end, or it becomes a chore instead of a running log:

- `README.md` — top-level summary + how to run
- `docs/architecture.md` — the pipeline diagram + why each tool was chosen
- `docs/business_problem.md` — Phase 2 output
- `docs/insights.md` — Phase 8 output
- `sql/schema.sql`, `sql/queries.sql`, `sql/views.sql`
- `docs/er_diagram.png` — export from Power BI's model view or draw.io

---

## Suggested pacing (if working part-time alongside other things)

| Week | Phases |
|---|---|
| 1 | 0, 1, 2, 3 |
| 2 | 4, 5, 6 |
| 3 | 7, 8 |
| 4 | 9, 10 |
| 5 | 11, 12 + polish |

Adjust freely — the sequencing matters more than the exact timeline.
