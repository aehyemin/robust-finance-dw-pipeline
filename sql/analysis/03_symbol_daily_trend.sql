SELECT
    stat_date,
    trade_count,
    volume,
    total_trade_amount
FROM mart.symbol_daily
WHERE symbol = 'AAPL'
ORDER BY stat_date