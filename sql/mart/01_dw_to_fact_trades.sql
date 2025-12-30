BEGIN;

INSERT INTO mart.fact_trades (trade_id, user_id, symbol, side, quantity, price, trade_ts, version, ingested_at, stat_date, trade_amount)
SELECT 
    trade_id,
    user_id,
    symbol,
    side,
    quantity,
    price,
    trade_ts,
    version, 
    ingested_at,
    trade_ts::date as stat_date,
    quantity * price as trade_amount
FROM dw.trades

ON CONFLICT (trade_id)
DO UPDATE SET
    user_id = EXCLUDED.user_id,
    symbol = EXCLUDED.symbol,
    side = EXCLUDED.side,
    quantity = EXCLUDED.quantity,
    price = EXCLUDED.price,
    trade_ts = EXCLUDED.trade_ts,
    version = EXCLUDED.version,
    ingested_at = EXCLUDED.ingested_at,
    stat_date = EXCLUDED.stat_date,
    trade_amount = EXCLUDED.trade_amount
WHERE
    EXCLUDED.version > mart.fact_trades.version;     

COMMIT;

