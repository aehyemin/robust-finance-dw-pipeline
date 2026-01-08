BEGIN;

INSERT INTO dw.trades (trade_id, user_id, symbol, side, quantity, price, trade_ts, version, ingested_at )
SELECT DISTINCT ON (trade_id)
    trade_id::bigint,
    user_id::bigint,
    upper(trim(symbol)),
    upper(trim(side)),
    quantity::NUMERIC(24, 8),
    price::NUMERIC(24, 8),
    trade_ts::TIMESTAMPTZ,
    version::int,
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
    AND version::int >= 1
    AND version ~ '^\d+$'


ORDER BY
    trade_id, version::int DESC

ON CONFLICT (trade_id)
DO UPDATE SET
    user_id = EXCLUDED.user_id,
    side = EXCLUDED.side,
    symbol = EXCLUDED.symbol,
    quantity = EXCLUDED.quantity,
    price = EXCLUDED.price,
    trade_ts = EXCLUDED.trade_ts,
    version = EXCLUDED.version,
    ingested_at = NOW()

WHERE
    EXCLUDED.version > dw.trades.version;     

COMMIT;