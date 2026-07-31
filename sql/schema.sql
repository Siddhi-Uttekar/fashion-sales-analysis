-- Fashion Intelligence Platform — Real Schema
-- Matches the actual database built in pgAdmin against the
-- Global Fashion Retail Sales dataset. Column types reflect
-- how each CSV's columns were actually typed during creation.

CREATE TABLE stores (
    store_id      INT PRIMARY KEY,
    country       TEXT,
    city          TEXT,
    store_name    TEXT,
    num_employees INT,
    zip_code      TEXT,
    latitude      NUMERIC,
    longitude     NUMERIC
);

CREATE TABLE products (
    product_id       INT PRIMARY KEY,
    category         TEXT,
    sub_category     TEXT,
    description_pt   TEXT,
    description_de   TEXT,
    description_fr   TEXT,
    description_es   TEXT,
    description_en   TEXT,
    description_zh   TEXT,
    color            TEXT,
    sizes            TEXT,
    production_cost  NUMERIC
);

CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    name          TEXT,
    email         TEXT,
    telephone     TEXT,
    city          TEXT,
    country       TEXT,
    gender        TEXT,
    date_of_birth DATE,
    job_title     TEXT
);

CREATE TABLE transactions (
    invoice_id        TEXT,
    line               INT,
    customer_id        INT REFERENCES customers(customer_id),
    product_id         INT REFERENCES products(product_id),
    size               TEXT,
    color              TEXT,
    unit_price         NUMERIC,
    quantity           INT,
    date               TIMESTAMP,
    discount           NUMERIC,
    line_total         NUMERIC,
    store_id           INT REFERENCES stores(store_id),
    employee_id        INT,
    currency           TEXT,
    currency_symbol    TEXT,
    sku                TEXT,
    transaction_type   TEXT,
    payment_method     TEXT,
    invoice_total      NUMERIC
);

-- Row counts after import (for reference — see docs/progress-log.md):
-- stores: 35 · products: 17,940 · customers: 1,643,306 · transactions: 6,416,827

-- One data-cleanup step applied after import:
UPDATE stores SET country = 'China' WHERE country = '中国';

-- Helpful indexes for the query patterns actually used in sql/queries.sql
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_product ON transactions(product_id);
CREATE INDEX idx_transactions_store ON transactions(store_id);
CREATE INDEX idx_transactions_customer ON transactions(customer_id);