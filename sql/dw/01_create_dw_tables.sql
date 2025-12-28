DROP TABLE IF EXISTS dw.trades;

CREATE TABLE dw.trades (
    trade_id BIGINT PRIMARY KEY,
    user_id BIGINT not null,
    symbol VARCHAR(32) not null,
    side VARCHAR(4) NOT NULL CHECK (side IN ('BUY', 'SELL')),
    quantity NUMERIC(24, 8) NOT NULL CHECK(quantity > 0),
    price NUMERIC(24, 8) NOT NULL CHECK(price > 0),
    trade_ts TIMESTAMPTZ NOT NULL,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX inx_dw_trade_ts ON dw.trades(trade_ts);
CREATE INDEX inx_dw_user_date ON dw.trades(user_id, trade_ts);
CREATE INDEX inx_dw_symbol_date ON dw.trades(symbol, trade_ts);

