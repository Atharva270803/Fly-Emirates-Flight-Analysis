-- ============================================================
-- FLY EMIRATES — PHASE 3: EDA & KPI QUERIES
-- All queries are grouped by dashboard page they feed into.
-- Run individually or all at once.
-- ============================================================

USE fly_emirates;

-- ============================================================
-- KPI 1: HEADLINE NUMBERS (Dashboard Overview Page)
-- ============================================================

-- 1a. Overall on-time performance rate
SELECT 
    ROUND(SUM(ON_TIME) * 100.0 / COUNT(ON_TIME), 2) AS on_time_pct
FROM flights
WHERE CANCELLED = 0;

-- 1b. Average arrival delay (excluding cancelled, excluding early arrivals)
-- Two versions: including early flights vs only delayed flights
SELECT
    ROUND(AVG(ARRIVAL_DELAY), 2)                                         AS avg_arrival_delay_all,
    ROUND(AVG(CASE WHEN ARRIVAL_DELAY > 0 THEN ARRIVAL_DELAY END), 2)   AS avg_arrival_delay_when_late
FROM flights
WHERE CANCELLED = 0;

-- 1c. Average departure delay
SELECT
    ROUND(AVG(DEPARTURE_DELAY), 2)                                           AS avg_departure_delay_all,
    ROUND(AVG(CASE WHEN DEPARTURE_DELAY > 0 THEN DEPARTURE_DELAY END), 2)   AS avg_departure_delay_when_late
FROM flights
WHERE CANCELLED = 0;

-- 1d. Cancellation rate
SELECT
    COUNT(*)                                        AS total_flights,
    SUM(CANCELLED)                                  AS total_cancelled,
    ROUND(SUM(CANCELLED) * 100.0 / COUNT(*), 2)    AS cancellation_rate_pct,
    SUM(DIVERTED)                                   AS total_diverted,
    ROUND(SUM(DIVERTED) * 100.0 / COUNT(*), 2)     AS diversion_rate_pct
FROM flights;

-- 1e. Delay cause breakdown — what % of total delay minutes each cause accounts for
SELECT
    ROUND(SUM(AIR_SYSTEM_DELAY)    * 100.0 / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 2) AS pct_air_system,
    ROUND(SUM(SECURITY_DELAY)      * 100.0 / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 2) AS pct_security,
    ROUND(SUM(AIRLINE_DELAY)       * 100.0 / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 2) AS pct_airline,
    ROUND(SUM(LATE_AIRCRAFT_DELAY) * 100.0 / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 2) AS pct_late_aircraft,
    ROUND(SUM(WEATHER_DELAY)       * 100.0 / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 2) AS pct_weather
FROM flights
WHERE CANCELLED = 0
  AND (AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY) > 0;

-- ============================================================
-- KPI 2: AIRLINE PERFORMANCE (Airline Page)
-- ============================================================

-- 2a. Full airline scorecard
SELECT
    a.AIRLINE                                                               AS airline_name,
    COUNT(*)                                                                AS total_flights,
    ROUND(SUM(f.ON_TIME) * 100.0 / COUNT(f.ON_TIME), 2)                   AS on_time_pct,
    ROUND(AVG(f.ARRIVAL_DELAY), 2)                                         AS avg_arrival_delay,
    ROUND(AVG(f.DEPARTURE_DELAY), 2)                                       AS avg_departure_delay,
    ROUND(SUM(f.CANCELLED) * 100.0 / COUNT(*), 2)                         AS cancellation_rate_pct,
    ROUND(SUM(f.DIVERTED)  * 100.0 / COUNT(*), 2)                         AS diversion_rate_pct,
    ROUND(AVG(f.AIR_TIME), 2)                                              AS avg_air_time_mins,
    SUM(CASE WHEN f.ARRIVAL_DELAY > 15 THEN 1 ELSE 0 END)                 AS total_late_flights
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
GROUP BY a.AIRLINE, f.AIRLINE
ORDER BY on_time_pct DESC;

-- 2b. Delay cause breakdown per airline
-- Shows which airlines suffer most from each delay type
SELECT
    a.AIRLINE                                           AS airline_name,
    ROUND(AVG(f.AIR_SYSTEM_DELAY), 2)                  AS avg_air_system_delay,
    ROUND(AVG(f.SECURITY_DELAY), 2)                    AS avg_security_delay,
    ROUND(AVG(f.AIRLINE_DELAY), 2)                     AS avg_airline_delay,
    ROUND(AVG(f.LATE_AIRCRAFT_DELAY), 2)               AS avg_late_aircraft_delay,
    ROUND(AVG(f.WEATHER_DELAY), 2)                     AS avg_weather_delay,
    ROUND(AVG(f.AIRLINE_DELAY + f.LATE_AIRCRAFT_DELAY), 2) AS avg_controllable_delay
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
WHERE f.CANCELLED = 0
GROUP BY a.AIRLINE, f.AIRLINE
ORDER BY avg_controllable_delay DESC;

-- 2c. Cancellation reasons per airline
SELECT
    a.AIRLINE                                           AS airline_name,
    f.CANCELLATION_LABEL                                AS reason,
    COUNT(*)                                            AS cancellations
FROM flights f
JOIN airlines a ON f.AIRLINE = a.IATA_CODE
WHERE f.CANCELLED = 1
GROUP BY a.AIRLINE, f.CANCELLATION_LABEL
ORDER BY a.AIRLINE, cancellations DESC;

-- ============================================================
-- KPI 3: AIRPORT PERFORMANCE (Airport Page)
-- ============================================================

-- 3a. Top 20 busiest origin airports with their on-time rate
SELECT
    f.ORIGIN_AIRPORT                                        AS airport_code,
    ap.AIRPORT                                              AS airport_name,
    ap.CITY,
    ap.STATE,
    COUNT(*)                                                AS total_departures,
    ROUND(SUM(f.ON_TIME) * 100.0 / COUNT(f.ON_TIME), 2)   AS on_time_pct,
    ROUND(AVG(f.DEPARTURE_DELAY), 2)                       AS avg_departure_delay,
    ROUND(SUM(f.CANCELLED) * 100.0 / COUNT(*), 2)         AS cancellation_rate_pct
FROM flights f
JOIN airports ap ON f.ORIGIN_AIRPORT = ap.IATA_CODE
WHERE f.CANCELLED = 0
GROUP BY f.ORIGIN_AIRPORT, ap.AIRPORT, ap.CITY, ap.STATE
ORDER BY total_departures DESC
LIMIT 20;

-- 3b. Top 20 worst airports by average arrival delay
SELECT
    f.DESTINATION_AIRPORT                                   AS airport_code,
    ap.AIRPORT                                              AS airport_name,
    ap.CITY,
    ap.STATE,
    COUNT(*)                                                AS total_arrivals,
    ROUND(AVG(f.ARRIVAL_DELAY), 2)                         AS avg_arrival_delay,
    ROUND(SUM(CASE WHEN f.ARRIVAL_DELAY > 15 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_arrival_pct
FROM flights f
JOIN airports ap ON f.DESTINATION_AIRPORT = ap.IATA_CODE
WHERE f.CANCELLED = 0
GROUP BY f.DESTINATION_AIRPORT, ap.AIRPORT, ap.CITY, ap.STATE
HAVING total_arrivals > 1000
ORDER BY avg_arrival_delay DESC
LIMIT 20;

-- 3c. Airport coordinates for map visual in dashboard
SELECT
    ap.IATA_CODE,
    ap.AIRPORT,
    ap.CITY,
    ap.STATE,
    ap.LATITUDE,
    ap.LONGITUDE,
    COUNT(*)                                                AS total_flights,
    ROUND(AVG(f.ARRIVAL_DELAY), 2)                         AS avg_arrival_delay,
    ROUND(SUM(f.ON_TIME) * 100.0 / COUNT(f.ON_TIME), 2)   AS on_time_pct
FROM flights f
JOIN airports ap ON f.DESTINATION_AIRPORT = ap.IATA_CODE
WHERE f.CANCELLED = 0
GROUP BY ap.IATA_CODE, ap.AIRPORT, ap.CITY, ap.STATE, ap.LATITUDE, ap.LONGITUDE
HAVING total_flights > 500
ORDER BY total_flights DESC;

-- ============================================================
-- KPI 4: TEMPORAL TRENDS (Trends Page)
-- ============================================================

-- 4a. Monthly performance trends
SELECT
    MONTH,
    COUNT(*)                                                AS total_flights,
    ROUND(SUM(ON_TIME) * 100.0 / COUNT(ON_TIME), 2)       AS on_time_pct,
    ROUND(AVG(ARRIVAL_DELAY), 2)                           AS avg_arrival_delay,
    ROUND(SUM(CANCELLED) * 100.0 / COUNT(*), 2)           AS cancellation_rate_pct
FROM flights
GROUP BY MONTH
ORDER BY MONTH;

-- 4b. Day of week performance
-- 1=Monday, 7=Sunday
SELECT
    DAY_OF_WEEK,
    CASE DAY_OF_WEEK
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END                                                     AS day_name,
    COUNT(*)                                                AS total_flights,
    ROUND(SUM(ON_TIME) * 100.0 / COUNT(ON_TIME), 2)       AS on_time_pct,
    ROUND(AVG(ARRIVAL_DELAY), 2)                           AS avg_arrival_delay,
    ROUND(SUM(CANCELLED) * 100.0 / COUNT(*), 2)           AS cancellation_rate_pct
FROM flights
GROUP BY DAY_OF_WEEK
ORDER BY DAY_OF_WEEK;

-- 4c. Departure hour performance
-- Which hours of day have worst delays?
SELECT
    FLOOR(SCHEDULED_DEPARTURE / 100)                        AS departure_hour,
    COUNT(*)                                                AS total_flights,
    ROUND(SUM(ON_TIME) * 100.0 / COUNT(ON_TIME), 2)       AS on_time_pct,
    ROUND(AVG(ARRIVAL_DELAY), 2)                           AS avg_arrival_delay
FROM flights
WHERE CANCELLED = 0
  AND SCHEDULED_DEPARTURE IS NOT NULL
GROUP BY departure_hour
ORDER BY departure_hour;

-- 4d. Weekly trend (full year view)
SELECT
    WEEK(FLIGHT_DATE)                                       AS week_number,
    MIN(FLIGHT_DATE)                                        AS week_start,
    COUNT(*)                                                AS total_flights,
    ROUND(SUM(ON_TIME) * 100.0 / COUNT(ON_TIME), 2)       AS on_time_pct,
    ROUND(AVG(ARRIVAL_DELAY), 2)                           AS avg_arrival_delay
FROM flights
WHERE CANCELLED = 0
GROUP BY WEEK(FLIGHT_DATE)
ORDER BY week_number;

-- ============================================================
-- KPI 5: ROUTE ANALYSIS (Supporting queries)
-- ============================================================

-- 5a. Top 20 busiest routes
SELECT
    f.ORIGIN_AIRPORT,
    f.DESTINATION_AIRPORT,
    CONCAT(f.ORIGIN_AIRPORT, ' → ', f.DESTINATION_AIRPORT) AS route,
    COUNT(*)                                                AS total_flights,
    ROUND(AVG(f.ARRIVAL_DELAY), 2)                         AS avg_arrival_delay,
    ROUND(SUM(f.ON_TIME) * 100.0 / COUNT(f.ON_TIME), 2)   AS on_time_pct,
    ROUND(AVG(f.DISTANCE), 0)                              AS avg_distance_miles
FROM flights f
WHERE f.CANCELLED = 0
GROUP BY f.ORIGIN_AIRPORT, f.DESTINATION_AIRPORT
ORDER BY total_flights DESC
LIMIT 20;

-- 5b. Most delayed routes (min 100 flights)
SELECT
    CONCAT(f.ORIGIN_AIRPORT, ' → ', f.DESTINATION_AIRPORT) AS route,
    COUNT(*)                                                AS total_flights,
    ROUND(AVG(f.ARRIVAL_DELAY), 2)                         AS avg_arrival_delay,
    ROUND(SUM(f.ON_TIME) * 100.0 / COUNT(f.ON_TIME), 2)   AS on_time_pct
FROM flights f
WHERE f.CANCELLED = 0
GROUP BY f.ORIGIN_AIRPORT, f.DESTINATION_AIRPORT
HAVING total_flights >= 100
ORDER BY avg_arrival_delay DESC
LIMIT 20;