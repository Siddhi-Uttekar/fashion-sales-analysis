"""
Phase 9 — AI Forecasting
Baseline (linear regression) first, then Prophet for seasonality.
"""
import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression

monthly_revenue = pd.read_parquet("data/processed/orders_clean.parquet")  # adjust to your KPI table

# --- Baseline: linear regression on month index ---
df = monthly_revenue.reset_index()
df["month_num"] = np.arange(len(df))
X = df[["month_num"]]
y = df["line_revenue"] if "line_revenue" in df else df.iloc[:, -1]

baseline_model = LinearRegression().fit(X, y)
next_month = pd.DataFrame({"month_num": [len(df)]})
print("Baseline forecast (next month):", baseline_model.predict(next_month)[0])

# --- Prophet: handles seasonality automatically ---
from prophet import Prophet

prophet_df = df.rename(columns={"order_date": "ds"}).assign(y=y)[["ds", "y"]]
model = Prophet(yearly_seasonality=True)
model.fit(prophet_df)

future = model.make_future_dataframe(periods=3, freq="M")
forecast = model.predict(future)

forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].tail(3).to_json(
    "backend/forecast_output.json", orient="records"
)
print(forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].tail(3))
