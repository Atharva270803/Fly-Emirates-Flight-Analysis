SET GLOBAL local_infile = 1;
-- ============================================================
-- FLY EMIRATES PROJECT — PHASE 1: DATABASE SETUP
-- Run this entire file once to create and verify your schema.
-- ============================================================

-- 1. CREATE DATABASE
CREATE DATABASE IF NOT EXISTS fly_emirates
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE fly_emirates;

-- ============================================================
-- 2. TABLE: airlines
-- Source: airlines.csv (14 rows)
-- ============================================================
DROP TABLE IF EXISTS airlines;

CREATE TABLE airlines (
  IATA_CODE  CHAR(2)      NOT NULL,
  AIRLINE    VARCHAR(100) NOT NULL,
  PRIMARY KEY (IATA_CODE)
);

-- ============================================================
-- 3. TABLE: airports
-- Source: airports.csv (322 rows)
-- ============================================================
DROP TABLE IF EXISTS airports;

CREATE TABLE airports (
  IATA_CODE  CHAR(3)        NOT NULL,
  AIRPORT    VARCHAR(150)   NOT NULL,
  CITY       VARCHAR(100),
  STATE      CHAR(2),
  COUNTRY    CHAR(3),
  LATITUDE   DECIMAL(9,5),
  LONGITUDE  DECIMAL(9,5),
  PRIMARY KEY (IATA_CODE)
);

-- ============================================================
-- 4. TABLE: flights
-- Source: flights.csv (~5.8 million rows, 500 MB)
-- Column types chosen carefully:
--   SMALLINT  for year, flight numbers (saves space at scale)
--   TINYINT   for month, day, day_of_week (1 byte, sufficient)
--   SMALLINT  for HHMM time columns (0–2359 fits in SMALLINT)
--   SMALLINT  for delay minutes (can be negative = early)
--   MEDIUMINT for distance (up to 8M miles, well within range)
--   CHAR(1)   for CANCELLATION_REASON (A/B/C/D)
-- ============================================================
DROP TABLE IF EXISTS flights;

CREATE TABLE flights (
  YEAR                  SMALLINT     NOT NULL,
  MONTH                 TINYINT      NOT NULL,
  DAY                   TINYINT      NOT NULL,
  DAY_OF_WEEK           TINYINT      NOT NULL,
  AIRLINE               CHAR(2)      NOT NULL,
  FLIGHT_NUMBER         SMALLINT     NOT NULL,
  TAIL_NUMBER           VARCHAR(10),
  ORIGIN_AIRPORT        CHAR(3)      NOT NULL,
  DESTINATION_AIRPORT   CHAR(3)      NOT NULL,
  SCHEDULED_DEPARTURE   SMALLINT,          -- HHMM integer e.g. 855 = 08:55
  DEPARTURE_TIME        SMALLINT,          -- actual departure HHMM
  DEPARTURE_DELAY       SMALLINT,          -- minutes, can be negative
  TAXI_OUT              SMALLINT,
  WHEELS_OFF            SMALLINT,
  SCHEDULED_TIME        SMALLINT,          -- planned flight duration (mins)
  ELAPSED_TIME          SMALLINT,          -- actual flight duration (mins)
  AIR_TIME              SMALLINT,
  DISTANCE              MEDIUMINT,
  WHEELS_ON             SMALLINT,
  TAXI_IN               SMALLINT,
  SCHEDULED_ARRIVAL     SMALLINT,
  ARRIVAL_TIME          SMALLINT,
  ARRIVAL_DELAY         SMALLINT,          -- minutes, can be negative
  DIVERTED              TINYINT(1),
  CANCELLED             TINYINT(1),
  CANCELLATION_REASON   CHAR(1),           -- A=Airline, B=Weather, C=NAS, D=Security
  AIR_SYSTEM_DELAY      SMALLINT,
  SECURITY_DELAY        SMALLINT,
  AIRLINE_DELAY         SMALLINT,
  LATE_AIRCRAFT_DELAY   SMALLINT,
  WEATHER_DELAY         SMALLINT,

  -- Indexes for the queries you'll run most often
  INDEX idx_airline       (AIRLINE),
  INDEX idx_origin        (ORIGIN_AIRPORT),
  INDEX idx_destination   (DESTINATION_AIRPORT),
  INDEX idx_month         (MONTH),
  INDEX idx_cancelled     (CANCELLED),
  INDEX idx_date          (YEAR, MONTH, DAY)
);

-- ============================================================
-- 5. LOAD DATA — airlines (fast, 14 rows)
-- Update the path to where your CSV files actually live.
-- ============================================================
LOAD DATA LOCAL INFILE 'D:/Atharva/PROJECTS/labmentix/project 4 Fly Emirates/airlines.csv'
INTO TABLE airlines
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(IATA_CODE, AIRLINE);

-- ============================================================
-- 6. LOAD DATA — airports (322 rows)
-- ============================================================
LOAD DATA LOCAL INFILE 'D:/Atharva/PROJECTS/labmentix/project 4 Fly Emirates/airports.csv'
INTO TABLE airports
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(IATA_CODE, AIRPORT, CITY, STATE, COUNTRY, LATITUDE, LONGITUDE);

-- ============================================================
-- 7. LOAD DATA — flights (500 MB, ~5.8M rows)
-- This will take 2–5 minutes. Do NOT close the terminal.
-- ============================================================
LOAD DATA LOCAL INFILE 'D:/Atharva/PROJECTS/labmentix/project 4 Fly Emirates/flights.csv'
INTO TABLE flights
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  YEAR, MONTH, DAY, DAY_OF_WEEK, AIRLINE, FLIGHT_NUMBER, TAIL_NUMBER,
  ORIGIN_AIRPORT, DESTINATION_AIRPORT, SCHEDULED_DEPARTURE, DEPARTURE_TIME,
  DEPARTURE_DELAY, TAXI_OUT, WHEELS_OFF, SCHEDULED_TIME, ELAPSED_TIME,
  AIR_TIME, DISTANCE, WHEELS_ON, TAXI_IN, SCHEDULED_ARRIVAL, ARRIVAL_TIME,
  ARRIVAL_DELAY, DIVERTED, CANCELLED, CANCELLATION_REASON,
  AIR_SYSTEM_DELAY, SECURITY_DELAY, AIRLINE_DELAY, LATE_AIRCRAFT_DELAY,
  WEATHER_DELAY
);

-- ============================================================
-- 8. VERIFICATION — run these after loading to confirm counts
-- ============================================================

-- Expected: 14
SELECT COUNT(*) AS airlines_count FROM airlines;

-- Expected: 322
SELECT COUNT(*) AS airports_count FROM airports;

-- Expected: ~5,819,079 (exact depends on dataset version)
SELECT COUNT(*) AS flights_count FROM flights;

-- Quick sanity check — sample 5 rows from each table
SELECT * FROM airlines LIMIT 5;
SELECT * FROM airports LIMIT 5;
SELECT * FROM flights LIMIT 5;

-- Check for obviously wrong values (should return 0 for all)
SELECT COUNT(*) AS bad_months  FROM flights WHERE MONTH  NOT BETWEEN 1 AND 12;
SELECT COUNT(*) AS bad_days    FROM flights WHERE DAY    NOT BETWEEN 1 AND 31;
SELECT COUNT(*) AS bad_dow     FROM flights WHERE DAY_OF_WEEK NOT BETWEEN 1 AND 7;
SELECT COUNT(*) AS bad_cancel  FROM flights WHERE CANCELLED NOT IN (0,1);


