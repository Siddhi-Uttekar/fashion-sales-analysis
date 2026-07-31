query = """
SELECT p.category, t.invoice_total, t.currency, t.quantity
FROM transactions t
JOIN products p ON p.product_id = t.product_id
"""
merged = pd.read_sql(query, engine)
print(merged.shape)
print(merged.head())

fx_to_usd = {"USD": 1.0, "EUR": 1.08, "GBP": 1.27, "CNY": 0.14}

merged["revenue_usd"] = merged["invoice_total"] * merged["currency"].map(fx_to_usd)

category_revenue = merged.groupby("category")["revenue_usd"].sum().sort_values(ascending=False)
print(category_revenue)

category_revenue.to_csv("data/processed/category_revenue.csv")