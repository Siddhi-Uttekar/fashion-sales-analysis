import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus

pd.options.display.float_format = '{:,.2f}'.format

password = quote_plus("REDACTED_PASSWORD")  # <-- put your real password here
engine = create_engine(f"postgresql+psycopg2://postgres:{password}@localhost:5432/fashion_db")

fx_to_usd = {"USD": 1.0, "EUR": 1.08, "GBP": 1.27, "CNY": 0.14}

# --- Revenue by category ---
query = """
SELECT p.category, t.invoice_total, t.currency, t.quantity
FROM transactions t
TABLESAMPLE SYSTEM (10)
JOIN products p ON p.product_id = t.product_id
"""
merged = pd.read_sql(query, engine)
merged["revenue_usd"] = merged["invoice_total"] * merged["currency"].map(fx_to_usd)
category_revenue = merged.groupby("category")["revenue_usd"].sum().sort_values(ascending=False)
print("=== Revenue by Category ===")
print(category_revenue)
category_revenue.to_csv("data/processed/category_revenue.csv")

# --- Revenue by country ---
query2 = """
SELECT s.country, t.invoice_total, t.currency
FROM transactions t
TABLESAMPLE SYSTEM (10)
JOIN stores s ON s.store_id = t.store_id
"""
by_country = pd.read_sql(query2, engine)
by_country["revenue_usd"] = by_country["invoice_total"] * by_country["currency"].map(fx_to_usd)
country_revenue = by_country.groupby("country")["revenue_usd"].sum().sort_values(ascending=False)
print("\n=== Revenue by Country ===")
print(country_revenue)
country_revenue.to_csv("data/processed/country_revenue.csv")

print("\nSaved both files!")

from sklearn.linear_model import LinearRegression
import numpy as np

# Reuse the monthly revenue trend, computed fresh here
query3 = """
SELECT
    DATE_TRUNC('month', date) AS month,
    SUM(CASE currency WHEN 'USD' THEN invoice_total WHEN 'EUR' THEN invoice_total*1.08
        WHEN 'GBP' THEN invoice_total*1.27 WHEN 'CNY' THEN invoice_total*0.14 ELSE invoice_total END) AS revenue_usd
FROM transactions
GROUP BY 1
ORDER BY 1
"""
monthly = pd.read_sql(query3, engine)
monthly["month_num"] = np.arange(len(monthly))

X = monthly[["month_num"]]
y = monthly["revenue_usd"]

model = LinearRegression().fit(X, y)

next_month_num = len(monthly)
predicted_revenue = model.predict([[next_month_num]])[0]

print(f"\n=== Forecast ===")
print(f"Predicted next month's revenue: ${predicted_revenue:,.2f}")

monthly.to_csv("data/processed/monthly_revenue.csv", index=False)