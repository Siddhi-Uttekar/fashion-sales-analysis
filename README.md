# Fashion Intelligence Platform

Analytics project on a 6.4M-row global fashion retail transaction dataset — SQL, Power BI, and Python, built as if scoping and delivering a real analytics engagement.

## The dataset
[Global Fashion Retail Sales](https://www.kaggle.com/) (Kaggle) — 6,416,827 transactions across 35 stores in 7 countries, 17,940 products, 1.64M customers. Chosen over several alternatives specifically because it has real transaction-level data *with* category, geography, and customer demographics together — most retail datasets on Kaggle have some of these, not all.

## Tools
- **PostgreSQL** — full dataset loaded and queried (no sampling)
- **Power BI** — 3 dashboard pages (Sales, Customers, Marketing)
- **Python (Pandas, scikit-learn)** — analysis and a baseline revenue forecast

## What I found

**Revenue mix:** Feminine (~$293M) and Masculine (~$245M) categories lead; Children's (~$64M) trails by ~4x. Coats & Blazers and Pants & Jeans are the top sub-categories by revenue; Accessories stands out as a high-volume, lower-price line.

**Seasonality:** revenue spikes sharply every December (+130-135% month-over-month, both years in the dataset) and crashes in January (-74 to -76%) — a strong, predictable holiday pattern, found using a SQL window function (`LAG()`) to compute month-over-month growth.

**Geography:** China and the United States are essentially tied at the top of revenue by country (~$160M each), both far ahead of Europe. Store-level data shows why for China specifically — 5 of the top 10 individual stores by revenue are Chinese stores, so its national total comes from several strong performers rather than one outlier.

**Customers:** female customers drive ~63% of revenue vs. ~36% male. Repeat purchase rate is 75.08% across the full dataset. Average order value is ~$344.

**Discounting:** full-price sales drive ~74% of revenue — discounting isn't the primary demand driver for this brand. Deep discounts (31%+) move more volume than moderate discounts, suggesting they're used for clearance rather than routine pricing.

## Two mistakes I caught and fixed (the actual interesting part)

1. **Currency bug** — the dataset mixes USD/EUR/GBP/CNY. Summing `invoice_total` raw made China look like it generated ~74% of total revenue. After converting everything to USD, China and the US are actually roughly tied — the original "finding" was a currency-unit illusion, not a real signal.

2. **Sampling bug** — an early Power BI dashboard, built on a ~100k-row sample of the transactions table, showed only a 0.7% repeat purchase rate. The denominator was being compared against all 1.64M customers in the master file, most of whom never appear in that small sample. Restricting the comparison to customers actually present in the sample raised it to 7.98% — and cross-checking against the *full* 6.4M-row dataset in SQL later revealed even that was understated: the real rate is 75.08%.

Both are documented in full in [`docs/insights.md`](docs/insights.md).

## Forecast
A simple linear regression baseline (scikit-learn) predicts next month's revenue at ~$26M. **Known limitation:** a straight-line model can't capture the December/January seasonality found in the SQL analysis above — a deliberate scoping choice given time constraints, not an oversight. A seasonal model (e.g. Prophet) would be the natural next step.

## Structure