Kaggle CSVs (stores, products, transactions, customers)
        │  imported via pgAdmin's CSV import
        ▼
PostgreSQL "fashion_db" — 4 tables, full data, no sampling
  stores (35) · products (17,940) · customers (1.64M) · transactions (6.4M)
        │
        ├─────────────────────┬─────────────────────┐
        ▼                     ▼                           │
  Power BI                Python (pandas)                 │
  (sample of ~100k        connects directly to            │
  transaction rows,       Postgres via SQLAlchemy,        │
  via Power Query)         runs on FULL dataset           │
        │                     │                           │
        ▼                     ▼                           │
  3 dashboard pages:    Re-derives the same        SQL queries
  Sales / Customers /   KPIs independently,         (sql/queries.sql)
  Marketing              as a cross-check            18 queries, run
        │                     │                       directly against
        │                     ▼                        the full dataset
        │              Linear regression                   │
        │              revenue forecast                    │
        │              (sklearn)                           │
        └──────────────────┬───────────────────────────────┘
                            ▼
                  docs/insights.md
                  (Observation → Cause → Action,
                   includes the currency and sampling
                   bugs found and corrected)
                            │
                            ▼
                     README.md (the portfolio story)