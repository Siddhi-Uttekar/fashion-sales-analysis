# Business Insights

Structure every insight as **Observation → Likely Cause → Recommended Action**.
Figures below are from the Global Fashion Retail Sales dataset. Where a Power BI
(sample-based) figure and a SQL (full-dataset) figure disagree, the SQL figure
is used as the trustworthy one — the discrepancy itself is noted, since it's a
real and useful finding about sampling risk.

## Data quality note (worth its own line in any writeup)
- **Currency:** the dataset mixes USD, EUR, GBP, and CNY. Raw sums across
  countries/categories are meaningless without conversion. All revenue figures
  here are corrected to USD using fixed snapshot rates (USD 1.0, EUR 1.08,
  GBP 1.27, CNY 0.14) — noted as a fixed-point-in-time conversion, not live FX.
- **Sampling risk:** an early Power BI dashboard was built on a ~100k-row
  sample of the 6.4M-row transactions table. This understated the repeat
  purchase rate dramatically (7.98% sampled vs. 75.08% on the full dataset) —
  a good reminder that small samples of large, sparse data structures
  (like customer purchase history) can badly misrepresent repeat-event rates.

## Sales
- **Observation:** Feminine (~$293M) and Masculine (~$245M) categories are the
  two largest revenue drivers; Children's (~$64M) trails both by roughly 4x.
- **Likely cause:** smaller addressable market/basket size for children's wear
  relative to adult categories.
- **Recommended action:** worth checking whether Children's underperformance
  is a market-size ceiling or an assortment/marketing gap before assuming
  it's not worth investment.

- **Observation:** Coats and Blazers and Pants and Jeans lead sub-categories
  by revenue; Accessories has a notably higher units-to-revenue ratio (454k
  units for ~$71M) than any other top-10 sub-category — a lower-price,
  higher-volume line.
- **Recommended action:** Accessories could be a strong candidate for
  cross-sell/bundle promotions given its volume.

## Geography
- **Observation:** China and the United States are essentially tied at the
  top (~$160M and ~$159M respectively, currency-corrected), both roughly
  2.5–3x every other country (Germany next at ~$69M).
- **Likely cause:** confirmed store counts are roughly equal across
  countries, so this is a genuine per-store performance gap, not a
  store-count artifact. Before the currency correction, raw (uncorrected)
  figures made China look like it generated ~74% of total revenue — this
  was a currency-unit illusion (CNY values look large as raw numbers vs. USD),
  not a real finding, and was corrected before being reported here.
- **Recommended action:** investigate why China/US per-store revenue
  outperforms Europe by this much — pricing, footfall, or product mix
  differences are the likely next questions.

## Customers
- **Observation:** Female customers generate ~$96L vs. ~$55L for male
  customers (from the Power BI sample); a small "D" (diverse/third gender,
  a legally recognized category in Germany) segment also present.
- **Observation:** Revenue decreases steadily with age — 18-24 is the top
  age bracket, 55+ the lowest, in the Power BI sample.
- **Observation:** Repeat purchase rate is 75.08% on the full 6.4M-row
  transaction dataset (the earlier 7.98% Power BI figure was a sampling
  artifact and should not be used/reported as the true rate).
- **Recommended action:** with a genuinely high three-quarters repeat rate,
  retention appears strong already — worth shifting focus to what drives
  the remaining ~25% one-and-done customers instead of assuming retention
  is the core problem.

## Marketing
- **Observation:** Full-price ("No Discount") sales account for ~74% of
  total revenue and the majority of units sold; among discounted tiers,
  31%+ discounts move noticeably more units than moderate (11-30%)
  discounts.
- **Likely cause:** deep discounts likely used for deliberate clearance/bulk
  movement rather than routine pricing strategy; moderate discounts don't
  appear to meaningfully drive extra volume over full price.
- **Recommended action:** given discounting isn't the primary revenue
  engine, consider whether moderate-discount promotions are worth the
  margin cost, or should be reserved for genuine clearance needs.
- **Observation:** Credit card is the dominant payment method (~80% of
  revenue) vs. cash (~20%).


# Business Insights

Structure every insight as **Observation → Likely Cause → Recommended Action**.
Figures below are from the Global Fashion Retail Sales dataset. Where a Power BI
(sample-based) figure and a SQL (full-dataset) figure disagree, the SQL figure
is used as the trustworthy one — the discrepancy itself is noted, since it's a
real and useful finding about sampling risk.

## Data quality note (worth its own line in any writeup)
- **Currency:** the dataset mixes USD, EUR, GBP, and CNY. Raw sums across
  countries/categories are meaningless without conversion. All revenue figures
  here are corrected to USD using fixed snapshot rates (USD 1.0, EUR 1.08,
  GBP 1.27, CNY 0.14) — noted as a fixed-point-in-time conversion, not live FX.
- **Sampling risk:** an early Power BI dashboard was built on a ~100k-row
  sample of the 6.4M-row transactions table. This understated the repeat
  purchase rate dramatically (7.98% sampled vs. 75.08% on the full dataset) —
  a good reminder that small samples of large, sparse data structures
  (like customer purchase history) can badly misrepresent repeat-event rates.

## Sales
- **Observation:** Feminine (~$293M) and Masculine (~$245M) categories are the
  two largest revenue drivers; Children's (~$64M) trails both by roughly 4x.
- **Likely cause:** smaller addressable market/basket size for children's wear
  relative to adult categories.
- **Recommended action:** worth checking whether Children's underperformance
  is a market-size ceiling or an assortment/marketing gap before assuming
  it's not worth investment.

- **Observation:** Coats and Blazers and Pants and Jeans lead sub-categories
  by revenue; Accessories has a notably higher units-to-revenue ratio (454k
  units for ~$71M) than any other top-10 sub-category — a lower-price,
  higher-volume line.
- **Recommended action:** Accessories could be a strong candidate for
  cross-sell/bundle promotions given its volume.

- **Observation:** Revenue is strongly seasonal — December spikes sharply
  both years (+135% MoM in Dec 2023, +130% in Dec 2024, both roughly
  doubling November), followed immediately by a steep January crash
  (-74% to