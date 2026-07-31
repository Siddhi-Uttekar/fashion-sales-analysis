"""
Phase 5.1 — Data Cleaning
Convert to a Jupyter notebook (`jupytext` or copy into cells) once you're
iterating interactively — kept as a plain script here so it's easy to diff
in git and run end-to-end.
"""
import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://user:password@localhost:5432/fashion_db")

orders = pd.read_sql("SELECT * FROM orders", engine)
order_items = pd.read_sql("SELECT * FROM order_items", engine)
customers = pd.read_sql("SELECT * FROM customers", engine)
products = pd.read_sql("SELECT * FROM products", engine)

# --- Missing values ---
print(orders.isna().sum())
print(order_items.isna().sum())
# Decide per-column: drop, fill with median/mode, or flag as 'unknown'

# --- Duplicates ---
print("Duplicate orders:", orders.duplicated(subset=["order_id"]).sum())

# --- Date parsing ---
orders["order_date"] = pd.to_datetime(orders["order_date"])

# --- Outlier detection (IQR method on order value) ---
order_value = order_items.groupby("order_id").apply(
    lambda df: (df["quantity"] * df["unit_price"] * (1 - df["discount"])).sum()
)
q1, q3 = order_value.quantile([0.25, 0.75])
iqr = q3 - q1
lower, upper = q1 - 1.5 * iqr, q3 + 1.5 * iqr
outliers = order_value[(order_value < lower) | (order_value > upper)]
print(f"Found {len(outliers)} outlier orders by value")

# --- Feature engineering ---
orders["order_month"] = orders["order_date"].dt.to_period("M")
orders["day_of_week"] = orders["order_date"].dt.day_name()

# Save cleaned frames for the next notebook
orders.to_parquet("data/processed/orders_clean.parquet")
order_items.to_parquet("data/processed/order_items_clean.parquet")
