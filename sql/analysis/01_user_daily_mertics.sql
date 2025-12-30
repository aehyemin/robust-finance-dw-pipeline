SELECT 
    user_id,
    stat_date,
    total_trade_amount
FROM mart.user_daily
WHERE user_id = 1
    AND stat_date = '2025-12-30'