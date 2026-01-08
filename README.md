# Robust Finance ELT Pipeline

![Python](https://img.shields.io/badge/Python-3.10-blue?logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-336791?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)

> PostgreSQL 기반의 **주식·코인 가상 거래 데이터 ELT 파이프라인**
> Raw 데이터 생성 -> DW 정합성 처리 -> Mart 집계 -> 비즈니스 분석

## About The Project
- **배경** : 금융 서비스에서 발생하는 로그는 수백만 건에 달하며, 네트워크 장애나 시스템 오류로 인해 중복 데이터가 발생하거나 도착 순서가 뒤바뀌는 문제가 발생합니다. 이러한 데이터가 그대로 분석에 사용될 경우, 잘못된 지표와 의사결정으로 이어질 수 있습니다.

- **목표** : 본 프로젝트는 단순히 데이터 적재를 넘어, **신뢰 가능한 분석 데이터는 어떻게 만들어지는가?** 라는 질문에서 출발했습니다.

  본 프로젝트의 목표는 다음과 같습니다.
  
  - 중복, 지연 데이터 상황에서도 정합성과 멱등성을 보장하는 DW 설계
  - 상세 Fact 및 집계(Aggregate) 중심의 데이터 마트 모델링을 실제로 적용
  - 분석 쿼리를 고려한 실사용 가능한 데이터 구조 설계 경험
    
## Getting Started
이 프로젝트는 Docker 환경에서 즉시 실행 가능하도록 구성했습니다.  

### Prerequisites
  - Docker & Docker Compose
  - Python 3.10+

### Installation and Execution

1. 레포지토리 클론
   ```
   git clone https://github.com/aehyemin/Robust-Finance-ELT-Pipeline.git
   ```
2. 환경 구성 및 실행
   ```
   cd Robust-Finance-ELT-Pipeline
   echo "AIRFLOW_UID=50000" > .env
   docker compose up -d
   ```
3. 가상 Raw 데이터 생성
   ```
   python3 scripts/generate_fake_data.py
   ```
4. Raw Layer 구축
   ```
   #1) 스키마/테이블 생성
   docker exec -i postgres_dw psql -U dw -d dw < sql/raw/00_create_schema.sql
   docker exec -i postgres_dw psql -U dw -d dw < sql/raw/01_create_raw_tables.sql

   #2) CSV -> raw.trades 적재
   docker exec -it postgres_dw psql -U dw -d dw -c "\COPY raw.trades (trade_id,user_id,symbol,side,quantity,price,trade_ts,version) FROM '/opt/data/raw_trades.csv' WITH (FORMAT csv, HEADER true);"
   ```
5. DW Layer 구축 (정제 및 Upsert)  
- 중복·지연 데이터 상황에서도 멱등성을 보장하기 위해, **trade_id 기준 Upsert 후 version 비교를 통해 최신 데이터만 유지하는 전략**을 적용했습니다.
   ```
   #1) DW 테이블 생성
   docker exec -i postgres_dw psql -U dw -d dw < sql/dw/01_create_dw_tables.sql

   #2) Raw -> DW 적재
   docker exec -i postgres_dw psql -U dw -d dw < sql/dw/02_raw_to_dw_trades_upsert.sql

   #3) DW 정합성 검증
   docker exec -i postgres_dw psql -U dw -d dw < sql/dw/00_dw_validation.sql
   ```
6. Mart Layer 구축
   ```
   #1) Mart 테이블 생성
   docker exec -i postgres_dw psql -U dw -d dw < sql/mart/00_create_mart_tables.sql

   #2) DW -> Fact 적재
   docker exec -i postgres_dw psql -U dw -d dw < sql/mart/01_dw_to_fact_trades.sql

   #3) 집계 테이블 적재
   docker exec -i postgres_dw psql -U dw -d dw < sql/mart/02_fact_aggregate.sql
   ```



## Data Model Overview 
| Table Name          | Type | Description |
|---------------------|------|-------------|
| mart.fact_trades    | Fact | 정제된 거래 단위의 상세 데이터 |
| mart.user_daily     | Agg  | 유저별 일일 거래 횟수 및 거래 금액 집계 |
| mart.symbol_daily   | Agg  | 종목(Symbol)별 일일 거래량 및 거래 대금 집계 |
| mart.user_total     | Agg  | 유저별 누적 거래 횟수 및 누적 거래 금액 |  

## Analysis Results
구축된 마트를 통해 다음과 같은 비즈니스 인사이트를 도출할 수 있습니다.
쿼리 파일은 **sql/analysis/** 디렉토리에서 확인할 수 있습니다.  

### 특정 유저의 일일 거래 금액
질문: 오늘 user_id = 1인 유저는 얼마를 거래했는가?
```
SELECT 
    user_id,
    stat_date,
    total_trade_amount
FROM mart.user_daily
WHERE user_id = 1
  AND stat_date = '2025-12-30';
```
결과  

<img width="349" height="70" alt="Screenshot from 2025-12-30 23-55-51" src="https://github.com/user-attachments/assets/da23c3ad-5bf3-4987-a5b8-f44bbce8697f" />  

### 누적 거래대금 기준 TOP 10 유저
질문: 지금까지 가장 많은 거래를 한 유저는 누구인가?
```
SELECT
    user_id,
    total_trade_count,
    total_trade_amount
FROM mart.user_total
ORDER BY total_trade_amount DESC
limit 10;
```
결과  

<img width="509" height="227" alt="Screenshot from 2025-12-30 23-58-10" src="https://github.com/user-attachments/assets/ffcb53b8-a395-4fba-b75e-85b4af8714e1" />  

### 특정 티커의 일별 거래 추이
질문: AAPL 종목의 일별 거래량 및 거래대금 변화는?
```
SELECT
    stat_date,
    trade_count,
    volume,
    total_trade_amount
FROM mart.symbol_daily
WHERE symbol = 'AAPL'
ORDER BY stat_date;
```

결과  

<img width="509" height="171" alt="Screenshot from 2025-12-30 23-57-35" src="https://github.com/user-attachments/assets/5cec8f6b-4d1e-46b8-b613-6ee0dfb1f300" />  

### 폴더 구조
```
Robust-Finance-ELT-Pipeline/
├── docker-compose.yml        # PostgreSQL / (Optional) Airflow 컨테이너 구성
├── README.md
├── .env
├── .gitignore
│
├── data/
│   └── raw_trades.csv        # 가상 거래 Raw 데이터 (CSV)
│
├── scripts/
│   └── generate_fake_data.py # 가상 Raw 데이터 생성 스크립트
│
└── sql/
   ├── raw/                  # Raw 스키마 및 적재
   │   ├── 00_create_schema.sql
   │   └── 01_create_raw_tables.sql
   │
   ├── dw/                   # DW 정제 및 Upsert 
   │   ├── 01_create_dw_tables.sql
   │   ├── 02_raw_to_dw_trades_upsert.sql
       └── 03_dw_validation.sql
   │
   ├── mart/                 # Fact / Aggregate Mart
   │   ├── 00_create_mart_tables.sql
   │   ├── 01_dw_to_fact_trades.sql
   │   └── 02_fact_aggregate.sql
   │
   └── analysis/             # 비즈니스 분석 SQL
       ├── 01_user_daily_metrics.sql
       ├── 02_top_n_user_trade.sql
       └── 03_symbol_daily_trend.sql
```





