BEGIN;

INSERT INTO dw.trades (trade_id, user_id, symbol, side, quantity, price, trade_ts, ingested_at )
SELECT
    trade_id::bigint,
    user_id::bigint,
    upper(trim(symbol)),
    upper(trim(side)),
    quantity::NUMERIC(24, 8),
    price::NUMERIC(24, 8),
    trade_ts::TIMESTAMPTZ,
    COALESCE(ingested_at, NOW())
FROM raw.trades

WHERE
    trade_id ~ '^\d+$'
    AND user_id ~ '^\d+$'
    AND upper(trim(side)) IN ('BUY', 'SELL')
    AND upper(trim(symbol)) != ''
    AND quantity ~ '^\d+(\.\d+)?$'
    AND price ~ '^\d+(\.\d+)?$'
    AND trade_ts IS NOT NULL
    AND trade_ts <> ''

ON CONFLICT (trade_id)
DO UPDATE SET
    user_id = EXCLUDED.user_id,
    side = EXCLUDED.side,
    symbol = EXCLUDED.symbol,
    quantity = EXCLUDED.quantity,
    price = EXCLUDED.price,
    trade_ts = EXCLUDED.trade_ts,
    ingested_at = GREATEST(dw.trades.ingested_at, EXCLUDED.ingested_at);

COMMIT;