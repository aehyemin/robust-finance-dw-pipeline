
DROP TABLE IF EXISTS mart.user_daily;
DROP TABLE IF EXISTS mart.symbol_daily;
DROP TABLE IF EXISTS mart.user_total;
DROP TABLE IF EXISTS mart.fact_trades;


CREATE TABLE mart.fact_trades (
    trade_id BIGINT PRIMARY KEY,
    user_id BIGINT not null,
    symbol VARCHAR(32) not null,
    side VARCHAR(4) NOT NULL CHECK (side IN ('BUY', 'SELL')),
    quantity NUMERIC(24, 8) NOT NULL CHECK(quantity > 0),
    price NUMERIC(24, 8) NOT NULL CHECK(price > 0),
    trade_ts TIMESTAMPTZ NOT NULL,
    version INT NOT NULL CHECK (version>=1),
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    stat_date DATE NOT NULL,
    trade_amount NUMERIC(32, 8) NOT NULL CHECK (trade_amount > 0)
);



CREATE TABLE mart.user_daily (
    user_id BIGINT not null,
    stat_date DATE NOT NULL,
    trade_count BIGINT NOT NULL,
    total_trade_amount NUMERIC(32, 8) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, stat_date)
);



CREATE TABLE mart.symbol_daily (
    symbol VARCHAR(32) NOT NULL,
    stat_date DATE NOT NULL,
    trade_count BIGINT NOT NULL,
    total_trade_amount NUMERIC(32, 8) NOT NULL,
    volume NUMERIC(32, 8) NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (symbol, stat_date)
);




CREATE TABLE mart.user_total (
    user_id            BIGINT PRIMARY KEY,
    total_trade_count  BIGINT NOT NULL,
    total_trade_amount NUMERIC(32,8) NOT NULL,
    to_date            DATE NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()

);


CREATE INDEX IF NOT EXISTS inx_fact_user_date ON mart.fact_trades(user_id, stat_date);
CREATE INDEX IF NOT EXISTS inx_fact_symbol_date ON mart.fact_trades(symbol, stat_date);
CREATE INDEX IF NOT EXISTS inx_fact_date ON mart.fact_trades(stat_date);
