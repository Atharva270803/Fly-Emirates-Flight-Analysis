# ✈️ Fly Emirates - US Flight Performance Analysis 2015

![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow?logo=powerbi)
![MySQL](https://img.shields.io/badge/MySQL-Database-blue?logo=mysql)
![SQL](https://img.shields.io/badge/SQL-Analysis-orange)
![Data](https://img.shields.io/badge/Records-5.8M%20Flights-green)

An end-to-end data analysis project covering **5,819,079 US domestic flights** from 2015. Built using MySQL for data ingestion, cleaning and KPI analysis, and Power BI for interactive dashboard visualisation.

---

## 📊 Live Dashboard

🔗 **[View Interactive Dashboard on Power BI](https://app.powerbi.com/view?r=eyJrIjoiNTFkYzQ4MjUtM2EzOS00OWVhLTgzNGItODU5YjhkZTFmMTA5IiwidCI6ImQxZjE0MzQ4LWYxYjUtNGEwOS1hYzk5LTdlYmYyMTNjYmM4MSIsImMiOjEwfQ%3D%3D)**

The dashboard covers 4 pages:
- **Flight Performance Overview** — headline KPIs and delay cause breakdown
- **Airline Performance Scorecard** — side-by-side comparison of all 14 airlines
- **Airport Performance & Map** — geographic view with bubble map
- **Delay Trends & Patterns** — monthly, weekly, daily and hourly patterns

---

## 🔑 Key Findings

| Metric | Value |
|---|---|
| Total Flights | 5,819,079 |
| On-Time Rate | 82.14% |
| Cancellation Rate | 1.54% |
| Avg Arrival Delay (all flights) | 4.40 mins |
| Avg Arrival Delay (when late) | 33.11 mins |
| Best Airline | Hawaiian Airlines — 89.47% on-time |
| Worst Airline | Spirit Air Lines — 71.25% on-time |
| Best Month | October — 88.17% on-time |
| Worst Month | June — 77.36% on-time |
| Best Departure Hour | 5am — 93.12% on-time |
| Worst Departure Hour | 8pm — 74.97% on-time |

**Most important finding:** 72% of all delay minutes are caused by factors within airline control (late aircraft + airline operational issues). Weather accounts for only 5%.

---

## 🗂️ Project Structure

```
fly-emirates-flight-analysis/
│
├── README.md
│
├── SQL/
│   ├── phase1.sql        # Database creation, table schema, data loading
│   ├── phase2.sql        # Data cleaning and computed column creation
│   └── phase3.sql          # All KPI and EDA queries (15 query groups)
│
└── Dataset/
    ├── airports.csv         # Dataset source information
    └── airlines.csv
```

---

## 🛠️ Tech Stack

- **Database:** MySQL 8.0
- **Analysis:** SQL (MySQL Workbench)
- **Visualisation:** Microsoft Power BI Desktop
- **Dataset:** 2015 Flight Delays and Cancellations (Kaggle)

---

## 📁 Dataset

The dataset consists of 3 CSV files:

| File | Rows | Size | Description |
|---|---|---|---|
| flights.csv | 5,819,079 | ~500MB | All US domestic flights in 2015 |
| airlines.csv | 14 | <1KB | Airline IATA codes and names |
| airports.csv | 322 | <1KB | Airport details with coordinates |

> **Note:** `flights.csv` is too large for GitHub (500MB). Download it from:
> 📥 [Kaggle — 2015 Flight Delays and Cancellations](https://www.kaggle.com/datasets/usdot/flight-delays)
>
> After downloading, place all 3 CSV files in your project folder and update the file paths in `sql/phase1.sql` before running.

---

## 🚀 How to Run This Project

### Prerequisites
- MySQL 8.0 or higher
- MySQL Workbench
- Power BI Desktop

### Step 1 — Set up the database
```sql
-- Open phase1.sql in MySQL Workbench
-- Update the file path on line 60 to your local CSV location:
-- 'D:/YOUR_PATH/flights.csv'
-- Run the full script
-- Expected: airlines=14 rows, airports=322 rows, flights=5,819,079 rows
```

### Step 2 — Clean the data
```sql
-- Open phase2.sql in MySQL Workbench
-- Run SET SESSION wait_timeout = 28800 first
-- Run all sections sequentially
-- Verify results match the expected values at the bottom of the file
```

### Step 3 — Run KPI queries
```sql
-- Open phase3.sql in MySQL Workbench
-- Run each KPI group independently
-- Results feed directly into the Power BI dashboard
```

### Step 4 — Connect Power BI
1. Open Power BI Desktop
2. Get Data → MySQL Database
3. Server: `localhost`, Database: `fly_emirates`
4. Select DirectQuery mode
5. Load all 3 tables

---

## 📈 Dashboard Pages

### Page 1 — Flight Performance Overview
Headline KPIs, flight status distribution donut chart, delay cause breakdown, and monthly on-time trend.

### Page 2 — Airline Performance Scorecard
Ranked comparison of all 14 airlines by on-time rate, average delays, cancellation rates, and controllable vs uncontrollable delay breakdown.

### Page 3 — Airport Performance & Map
Interactive bubble map of US airports sized by flight volume and colored by performance. Top 15 busiest, best, and worst airports.

### Page 4 — Delay Trends & Patterns
Monthly trend line, day-of-week comparison, departure hour analysis (the 93%→74% on-time drop), full year weekly area chart, and month×day heatmap matrix.

---

## 💡 Recommendations

**For passengers:**
- Fly on Saturdays in September or October
- Book the earliest departure available (5am = 93% on-time)
- Prefer Hawaiian or Alaska Airlines
- Avoid LaGuardia, avoid Monday evenings, avoid February

**For airlines:**
- 72% of delay minutes are controllable — focus on reducing late aircraft cascades through better turnaround scheduling
- American Eagle's 5.10% cancellation rate (3x industry average) indicates structural operational issues

**For airports:**
- Chicago O'Hare (14 min avg departure delay) and LaGuardia (10.33 min avg arrival delay) create network-wide ripple effects — capacity intervention needed

---

## 📄 License

This project is for educational purposes. Flight data sourced from the US Department of Transportation via Kaggle.
