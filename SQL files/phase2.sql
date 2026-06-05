-- ============================================================
-- FLY EMIRATES — PHASE 2: DATA CLEANING & PREPARATION
-- Final verified version
-- ============================================================

USE fly_emirates;

-- ============================================================
-- SECTION 1: UNDERSTAND YOUR NULLS
-- ============================================================

-- 1a. Cancellation vs non-cancellation count
SELECT 
    CANCELLED,
    COUNT(*) AS flight_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM flights
GROUP BY CANCELLED;

-- 1b. NULL counts per column
SELECT
    SUM(CASE WHEN DEPARTURE_TIME      IS NULL THEN 1 ELSE 0 END) AS null_departure_time,
    SUM(CASE WHEN DEPARTURE_DELAY     IS NULL THEN 1 ELSE 0 END) AS null_departure_delay,
    SUM(CASE WHEN ARRIVAL_TIME        IS NULL THEN 1 ELSE 0 END) AS null_arrival_time,
    SUM(CASE WHEN ARRIVAL_DELAY       IS NULL THEN 1 ELSE 0 END) AS null_arrival_delay,
    SUM(CASE WHEN AIR_TIME            IS NULL THEN 1 ELSE 0 END) AS null_air_time,
    SUM(CASE WHEN ELAPSED_TIME        IS NULL THEN 1 ELSE 0 END) AS null_elapsed_time,
    SUM(CASE WHEN AIR_SYSTEM_DELAY    IS NULL THEN 1 ELSE 0 END) AS null_air_system_delay,
    SUM(CASE WHEN SECURITY_DELAY      IS NULL THEN 1 ELSE 0 END) AS null_security_delay,
    SUM(CASE WHEN AIRLINE_DELAY       IS NULL THEN 1 ELSE 0 END) AS null_airline_delay,
    SUM(CASE WHEN LATE_AIRCRAFT_DELAY IS NULL THEN 1 ELSE 0 END) AS null_late_aircraft_delay,
    SUM(CASE WHEN WEATHER_DELAY       IS NULL THEN 1 ELSE 0 END) AS null_weather_delay,
    SUM(CASE WHEN CANCELLATION_REASON IS NULL THEN 1 ELSE 0 END) AS null_cancel_reason,
    SUM(CASE WHEN TAIL_NUMBER         IS NULL THEN 1 ELSE 0 END) AS null_tail_number
FROM flights;

-- 1c. Check values on cancelled flights
-- MySQL loaded empty strings as 0 (not NULL) due to strict mode being off
-- Cancelled flights show 0 in operational columns — these need to become NULL
SELECT 
    DEPARTURE_TIME,
    DEPARTURE_DELAY,
    ARRIVAL_TIME,
    ARRIVAL_DELAY,
    AIR_SYSTEM_DELAY,
    CANCELLATION_REASON
FROM flights
WHERE CANCELLED = 1
LIMIT 10;

-- 1d. Confirm no NULLs exist on non-cancelled flights
SELECT COUNT(*) AS nulls_on_non_cancelled
FROM flights
WHERE DEPARTURE_TIME IS NULL AND CANCELLED = 0;

-- 1e. Confirm all cancelled flights have 0 in operational columns
SELECT COUNT(*) AS cancelled_with_departure
FROM flights
WHERE CANCELLED = 1 AND DEPARTURE_TIME IS NOT NULL;

-- ============================================================
-- SECTION 2: FIX CANCELLED FLIGHTS — SET OPERATIONAL COLUMNS TO NULL
-- MySQL stored empty strings as 0 during load.
-- 0 is not valid for cancelled flights (no departure time, no delay, etc.)
-- Setting these to NULL so they don't corrupt averages in analysis.
-- ============================================================

SET SESSION wait_timeout = 28800;
SET SESSION interactive_timeout = 28800;
SET SQL_SAFE_UPDATES = 0;

UPDATE flights
SET
    DEPARTURE_TIME      = NULL,
    DEPARTURE_DELAY     = NULL,
    TAXI_OUT            = NULL,
    WHEELS_OFF          = NULL,
    ELAPSED_TIME        = NULL,
    AIR_TIME            = NULL,
    WHEELS_ON           = NULL,
    TAXI_IN             = NULL,
    ARRIVAL_TIME        = NULL,
    ARRIVAL_DELAY       = NULL,
    AIR_SYSTEM_DELAY    = NULL,
    SECURITY_DELAY      = NULL,
    AIRLINE_DELAY       = NULL,
    LATE_AIRCRAFT_DELAY = NULL,
    WEATHER_DELAY       = NULL
WHERE CANCELLED = 1;
-- Expected: 89884 row(s) affected

SET SQL_SAFE_UPDATES = 1;

-- ============================================================
-- SECTION 3: FIX AIRPORTS — 3 ROWS WITH MISSING COORDINATES
-- ECP, PBG, UST had 0.0 stored for LATITUDE and LONGITUDE
-- ============================================================

-- Verify which airports have 0 coordinates
SELECT IATA_CODE, AIRPORT, CITY, STATE, LATITUDE, LONGITUDE
FROM airports
WHERE LATITUDE = 0 OR LONGITUDE = 0;

-- Fix coordinates for the 3 affected airports
UPDATE airports SET LATITUDE = 30.35780, LONGITUDE = -85.79720
WHERE IATA_CODE = 'ECP';

UPDATE airports SET LATITUDE = 44.65090, LONGITUDE = -73.46810
WHERE IATA_CODE = 'PBG';

UPDATE airports SET LATITUDE = 29.95920, LONGITUDE = -81.33970
WHERE IATA_CODE = 'UST';
-- Expected: 1 row(s) affected each

-- ============================================================
-- SECTION 4: ADD COMPUTED COLUMNS FOR ANALYSIS
-- ============================================================

SET SQL_SAFE_UPDATES = 0;

-- 4a. Proper DATE column reconstructed from YEAR / MONTH / DAY integers
ALTER TABLE flights ADD COLUMN FLIGHT_DATE DATE;
ALTER TABLE flights ADD INDEX idx_flight_date (FLIGHT_DATE);

UPDATE flights
SET FLIGHT_DATE = STR_TO_DATE(
    CONCAT(YEAR, '-', LPAD(MONTH, 2, '0'), '-', LPAD(DAY, 2, '0')),
    '%Y-%m-%d'
);
-- Expected: 5819079 row(s) affected

-- 4b. ON_TIME flag
-- 1 = arrived 15 min late or less (industry standard)
-- 0 = arrived more than 15 min late
-- NULL = cancelled (excluded from on-time calculations)
ALTER TABLE flights ADD COLUMN ON_TIME TINYINT(1);

UPDATE flights
SET ON_TIME = CASE
    WHEN CANCELLED = 1       THEN NULL
    WHEN ARRIVAL_DELAY <= 15 THEN 1
    ELSE                          0
END;
-- Expected: 5819079 row(s) matched

-- 4c. DELAY_CATEGORY — human readable delay severity bucket
ALTER TABLE flights ADD COLUMN DELAY_CATEGORY VARCHAR(20);

UPDATE flights
SET DELAY_CATEGORY = CASE
    WHEN CANCELLED = 1                         THEN 'Cancelled'
    WHEN ARRIVAL_DELAY IS NULL                 THEN 'Diverted'
    WHEN ARRIVAL_DELAY <= 0                    THEN 'Early/On Time'
    WHEN ARRIVAL_DELAY BETWEEN 1 AND 15        THEN 'Minor (1-15 min)'
    WHEN ARRIVAL_DELAY BETWEEN 16 AND 45       THEN 'Moderate (16-45 min)'
    WHEN ARRIVAL_DELAY BETWEEN 46 AND 120      THEN 'Severe (46-120 min)'
    ELSE                                            'Critical (>120 min)'
END;
-- Expected: 5819079 row(s) affected

-- 4d. CANCELLATION_LABEL — decode A/B/C/D to readable text
ALTER TABLE flights ADD COLUMN CANCELLATION_LABEL VARCHAR(30);

UPDATE flights
SET CANCELLATION_LABEL = CASE CANCELLATION_REASON
    WHEN 'A' THEN 'Airline/Carrier'
    WHEN 'B' THEN 'Weather'
    WHEN 'C' THEN 'National Air System'
    WHEN 'D' THEN 'Security'
    ELSE NULL
END;
-- Expected: 89884 row(s) affected (only cancelled flights get a label)

SET SQL_SAFE_UPDATES = 1;

-- ============================================================
-- SECTION 5: FINAL VERIFICATION
-- ============================================================

-- 5a. No delay NULLs on non-cancelled flights (expected: all 0)
SELECT
    SUM(CASE WHEN AIR_SYSTEM_DELAY    IS NULL THEN 1 ELSE 0 END) AS null_air_system,
    SUM(CASE WHEN SECURITY_DELAY      IS NULL THEN 1 ELSE 0 END) AS null_security,
    SUM(CASE WHEN AIRLINE_DELAY       IS NULL THEN 1 ELSE 0 END) AS null_airline,
    SUM(CASE WHEN LATE_AIRCRAFT_DELAY IS NULL THEN 1 ELSE 0 END) AS null_late_aircraft,
    SUM(CASE WHEN WEATHER_DELAY       IS NULL THEN 1 ELSE 0 END) AS null_weather
FROM flights
WHERE CANCELLED = 0;

-- 5b. Delay category distribution
SELECT DELAY_CATEGORY, COUNT(*) AS flights
FROM flights
GROUP BY DELAY_CATEGORY
ORDER BY flights DESC;

-- 5c. Cancellation reason breakdown
SELECT CANCELLATION_LABEL, COUNT(*) AS count
FROM flights
WHERE CANCELLED = 1
GROUP BY CANCELLATION_LABEL;

-- 5d. Date range (expected: 2015-01-01 to 2015-12-31)
SELECT MIN(FLIGHT_DATE), MAX(FLIGHT_DATE)
FROM flights;

-- 5e. On-time rate (result: 82.14%)
SELECT ROUND(SUM(ON_TIME) * 100.0 / COUNT(ON_TIME), 2) AS on_time_pct
FROM flights
WHERE CANCELLED = 0;

-- 5f. Total flights summary
SELECT
    COUNT(*)                                                     AS total_flights,
    SUM(CANCELLED)                                               AS total_cancelled,
    SUM(DIVERTED)                                                AS total_diverted,
    SUM(CASE WHEN CANCELLED = 0 AND DIVERTED = 0 THEN 1 END)    AS completed_flights
FROM flights;

-- ============================================================
-- VERIFIED RESULTS
-- 5a: all 0
-- 5b: Early/On Time 3,642,299 | Minor 1,063,398 | Moderate 586,325
--     Severe 322,753 | Critical 114,420 | Cancelled 89,884
-- 5c: Weather 48,851 | Airline/Carrier 25,262 | NAS 15,749 | Security 22
-- 5d: 2015-01-01 to 2015-12-31
-- 5e: 82.14%
-- 5f: 5,819,079 total | 89,884 cancelled | 15,187 diverted | 5,714,008 completed
-- ============================================================