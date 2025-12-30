SELECT
    user_id,
    total_trade_count,
    total_trade_amount
FROM mart.user_total
ORDER BY total_trade_amount DESC
limit 10;