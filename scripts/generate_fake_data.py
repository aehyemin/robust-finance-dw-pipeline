import csv
import random
from datetime import datetime, timedelta, timezone
import os

OUTPUT_DIR="robust-finance-dw-pipeline/data"
OUTPUT_FILE=os.path.join(OUTPUT_DIR, "raw_trades.csv")
os.makedirs(OUTPUT_DIR, exist_ok=True)


symbols = ["AAPL", "MSFT", "TSLA", "AMD", "BTC", "ETH"]
sides = ["BUY", "SELL", "buy", "sell"]
start_date = datetime(2025, 12, 25, tzinfo=timezone.utc)

MAX_VERSION = 100
max_version_by_trade_id = {}

def generate_data():
    print("data gen")

    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['trade_id', 'user_id', 'symbol', 'side', 'quantity', 'price', 'trade_ts', 'version'])

        for i in range(1, 10001):
            trade_id = i if random.random() > 0.05 else random.randint(1,100)
            
            user_id = random.randint(1, 50)

            symbol = random.choice(symbols)
            if random.random() < 0.10:
                symbol = ""
            
            side = random.choice(sides)
            if random.random() < 0.10:
                side = 'nothing'

            if random.random() < 0.10:
                quantity =""
            else:
                quantity= round(random.uniform(0.1, 100), 4)

            if random.random() < 0.10:
                price=""
            else:
                price= round(random.uniform(100, 20000), 4)

            now = datetime.now(timezone.utc)
            if random.random() < 0.10:
                trade_ts = (now - timedelta(days=random.randint(1,5))).isoformat()
            else:
                random_time = random.randint(0, 60*60*24*10)
                trade_ts = (start_date + timedelta(seconds=random_time)).isoformat()


            cur = max_version_by_trade_id.get(trade_id, 1)
            if trade_id <= 100:
                if random.random() < 0.10 and cur < MAX_VERSION:
                    cur += 1
            max_version_by_trade_id[trade_id] = cur
            version = cur


            writer.writerow([trade_id, user_id, symbol, side, quantity, price, trade_ts, version])


        print("data gen complete")

if __name__ == '__main__':
    generate_data()