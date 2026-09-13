-- ============================================================================
-- CS G516: Advanced Database Systems - Spatiotemporal Query Engine
-- Milestone 4: Advanced Spatial, Temporal, Spatio-Temporal & Analytical Queries
-- Database: PostgreSQL + PostGIS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SPATIAL QUERY: Proximity Search (ST_DWithin)
-- Question: Which active drivers were within 500 meters of the central library (77.592, 12.972)?
-- Optimization: Utilizes Spatial GiST Index on location_trace.location.
-- ----------------------------------------------------------------------------
SELECT DISTINCT 
    d.driver_id, 
    d.driver_name,
    d.vehicle_type,
    ROUND(ST_Distance(t.location::geography, ST_SetSRID(ST_MakePoint(77.592, 12.972), 4326)::geography)::numeric, 2) AS distance_meters
FROM location_trace t
JOIN driver d ON t.driver_id = d.driver_id
WHERE ST_DWithin(
    t.location::geography, 
    ST_SetSRID(ST_MakePoint(77.592, 12.972), 4326)::geography, 
    500
)
ORDER BY distance_meters ASC;

-- ----------------------------------------------------------------------------
-- 2. TEMPORAL QUERY: Time-Window Activity Filtering
-- Question: Which driver trajectories recorded telemetry pings during the morning rush (08:00 AM - 10:00 AM)?
-- ----------------------------------------------------------------------------
SELECT 
    d.driver_id,
    d.driver_name,
    COUNT(t.trace_id) AS morning_pings,
    MIN(t.recorded_at) AS first_active_time,
    MAX(t.recorded_at) AS last_active_time
FROM location_trace t
JOIN driver d ON t.driver_id = d.driver_id
WHERE t.recorded_at::time BETWEEN '08:00:00' AND '10:00:00'
GROUP BY d.driver_id, d.driver_name
ORDER BY morning_pings DESC;

-- ----------------------------------------------------------------------------
-- 3. SPATIO-TEMPORAL QUERY: Zone Entry within Time Window (ST_Contains + Timestamp)
-- Question: Which drivers entered 'Academic Block North' between 08:00 AM and 11:00 AM?
-- ----------------------------------------------------------------------------
SELECT DISTINCT 
    t.driver_id, 
    d.driver_name,
    z.zone_name, 
    MIN(t.recorded_at) AS first_zone_entry_time
FROM location_trace t
JOIN driver d ON t.driver_id = d.driver_id
JOIN campus_zone z ON ST_Contains(z.boundary, t.location)
WHERE z.zone_name = 'Academic Block North'
  AND t.recorded_at::time BETWEEN '08:00:00' AND '11:00:00'
GROUP BY t.driver_id, d.driver_name, z.zone_name
ORDER BY first_zone_entry_time ASC;

-- ----------------------------------------------------------------------------
-- 4. MOVEMENT & TRAJECTORY QUERY: Path Reconstruction & Trajectory Similarity (ST_FrechetDistance)
-- Question: Reconstruct trajectory linestrings and compute Fréchet similarity distance between trips.
-- ----------------------------------------------------------------------------
WITH DeliveryTrajectories AS (
    SELECT 
        delivery_id,
        driver_id,
        ST_MakeLine(location ORDER BY recorded_at) AS trajectory_path
    FROM location_trace
    GROUP BY delivery_id, driver_id
    HAVING COUNT(trace_id) >= 2
)
SELECT 
    t1.delivery_id AS trip_1,
    t2.delivery_id AS trip_2,
    t1.driver_id AS driver_1,
    t2.driver_id AS driver_2,
    ROUND(ST_FrechetDistance(t1.trajectory_path, t2.trajectory_path)::numeric, 6) AS frechet_similarity_score
FROM DeliveryTrajectories t1
JOIN DeliveryTrajectories t2 ON t1.delivery_id < t2.delivery_id
ORDER BY frechet_similarity_score ASC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 5. SPATIO-TEMPORAL ANALYTICAL QUERY: Demand Volume Heatmap by Zone & Hour
-- Question: How does order delivery demand vary across campus zones and hours of the day?
-- ----------------------------------------------------------------------------
SELECT 
    z.zone_name,
    EXTRACT(HOUR FROM dr.created_at)::int AS hour_of_day,
    COUNT(dr.delivery_id) AS total_orders,
    COUNT(DISTINCT dr.driver_id) AS unique_drivers_assigned
FROM delivery_request dr
JOIN customer c ON dr.customer_id = c.customer_id
JOIN campus_zone z ON ST_Contains(z.boundary, c.location)
GROUP BY z.zone_name, hour_of_day
ORDER BY hour_of_day ASC, total_orders DESC;

-- ============================================================================
-- ADDITIONAL EVALUATOR DEFENSE QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 6. TRAJECTORY METRICS: Velocity & Total Distance Covered per Trip
-- Question: Calculate total trip length (meters), duration (seconds), and average speed (m/s).
-- ----------------------------------------------------------------------------
SELECT 
    t.delivery_id,
    d.driver_name,
    COUNT(t.trace_id) AS telemetry_points,
    ROUND(ST_Length(ST_MakeLine(t.location ORDER BY t.recorded_at)::geography)::numeric, 2) AS distance_meters,
    EXTRACT(EPOCH FROM (MAX(t.recorded_at) - MIN(t.recorded_at))) AS duration_seconds,
    CASE 
        WHEN EXTRACT(EPOCH FROM (MAX(t.recorded_at) - MIN(t.recorded_at))) > 0 
        THEN ROUND((ST_Length(ST_MakeLine(t.location ORDER BY t.recorded_at)::geography) / 
                    EXTRACT(EPOCH FROM (MAX(t.recorded_at) - MIN(t.recorded_at))))::numeric, 2)
        ELSE 0 
    END AS avg_speed_mps
FROM location_trace t
JOIN driver d ON t.driver_id = d.driver_id
GROUP BY t.delivery_id, d.driver_name
HAVING COUNT(t.trace_id) >= 2
ORDER BY distance_meters DESC;

-- ----------------------------------------------------------------------------
-- 7. K-NEAREST NEIGHBORS (KNN): Index-Accelerated Proximity Search (<-> Operator)
-- Question: Find the 3 nearest restaurants to a specific customer location using PostGIS KNN operator.
-- ----------------------------------------------------------------------------
SELECT 
    r.restaurant_id,
    r.restaurant_name,
    ROUND(ST_Distance(r.location::geography, c.location::geography)::numeric, 2) AS distance_meters
FROM customer c
CROSS JOIN restaurant r
WHERE c.customer_id = 1
ORDER BY r.location <-> c.location
LIMIT 3;

-- ----------------------------------------------------------------------------
-- 8. COMPLIANCE & ANOMALY: Geofence Breach Detection
-- Question: Identify telemetry pings where driver was outside their assigned customer delivery zone.
-- ----------------------------------------------------------------------------
WITH ActiveDeliveryZones AS (
    SELECT 
        dr.order_id,
        z.zone_name AS assigned_zone,
        z.boundary
    FROM delivery_request dr
    JOIN customer c ON dr.customer_id = c.customer_id
    JOIN campus_zone z ON ST_Contains(z.boundary, c.location)
)
SELECT 
    t.trace_id,
    t.delivery_id,
    t.driver_id,
    adz.assigned_zone,
    t.recorded_at AS breach_time,
    ST_AsText(t.location) AS breach_point
FROM location_trace t
JOIN ActiveDeliveryZones adz ON t.delivery_id = adz.order_id
WHERE NOT ST_Contains(adz.boundary, t.location)
ORDER BY t.recorded_at DESC;

-- ----------------------------------------------------------------------------
-- 9. SPATIAL DENSITY: Telemetry Ping Distribution Across Campus Zones
-- Question: Aggregates total ping volume per zone to identify spatial traffic hotspots.
-- ----------------------------------------------------------------------------
SELECT 
    z.zone_id,
    z.zone_name,
    COUNT(t.trace_id) AS total_ping_volume,
    COUNT(DISTINCT t.driver_id) AS active_drivers
FROM campus_zone z
LEFT JOIN location_trace t ON ST_Contains(z.boundary, t.location)
GROUP BY z.zone_id, z.zone_name
ORDER BY total_ping_volume DESC;

-- ----------------------------------------------------------------------------
-- 10. SPATIO-TEMPORAL GAP: Driver Idle/Signal Loss Detection (LAG Window Function)
-- Question: Detect gaps greater than 2 minutes between consecutive telemetry pings for active deliveries.
-- ----------------------------------------------------------------------------
WITH TelemetryGaps AS (
    SELECT 
        trace_id,
        delivery_id,
        driver_id,
        recorded_at,
        LAG(recorded_at) OVER (PARTITION BY delivery_id ORDER BY recorded_at) AS prev_ping_time,
        EXTRACT(EPOCH FROM (recorded_at - LAG(recorded_at) OVER (PARTITION BY delivery_id ORDER BY recorded_at))) AS gap_seconds
    FROM location_trace
)
SELECT 
    delivery_id,
    driver_id,
    prev_ping_time,
    recorded_at AS resume_ping_time,
    gap_seconds
FROM TelemetryGaps
WHERE gap_seconds > 120
ORDER BY gap_seconds DESC;