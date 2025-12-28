DROP TABLE IF EXISTS raw.trades;

CREATE TABLE raw.trades (
    trade_id TEXT,
    user_id TEXT,
    symbol TEXT,
    side TEXT,
    quantity TEXT,
    price TEXT,
    trade_ts TEXT,
    ingested_at TIMESTAMPTZ DEFAULT NOW()
);