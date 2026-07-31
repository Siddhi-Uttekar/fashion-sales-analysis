"""
Phase 5.2 / Phase 6 — Sales Analysis & KPI Calculation
"""
import pandas as pd
import matplotlib.pyplot as plt

orders = pd.read_parquet("data/processed/orders_clean.parquet")
order_items = pd.read_parquet("data/processed/order_items_clean.parquet")

merged = order_items.merge(orders, on="order_id")
merged["line_revenue"] = merged["quantity"] * merged["unit_price"] * (1 - merged["discount"])

# --- KPI: monthly revenue ---
monthly_revenue = merged.groupby(merged["order_date"].dt.to_period("M"))["line_revenue"].sum()

# --- KPI: average order value ---
order_value = merged.groupby("order_id")["line_revenue"].sum()
avg_order_value = order_value.mean()
print("Average Order Value:", round(avg_order_value, 2))

# --- KPI: repeat purchase rate ---
orders_per_customer = orders.groupby("customer_id")["order_id"].nunique()
repeat_rate = (orders_per_customer > 1).mean()
print("Repeat Purchase Rate:", round(repeat_rate * 100, 2), "%")

# --- Pivot: revenue by category over time (if category joined in) ---
# pivot = merged.pivot_table(index="order_month", columns="category_name",
#                             values="line_revenue", aggfunc="sum")

# --- Quick visualization ---
monthly_revenue.plot(kind="line", title="Monthly Revenue")
plt.ylabel("Revenue")
plt.tight_layout()
plt.savefig("docs/screenshots/monthly_revenue.png")
