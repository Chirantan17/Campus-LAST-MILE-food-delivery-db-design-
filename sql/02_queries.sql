-- ============================================================================
-- MILESTONE 4: ADVANCED SPATIOTEMPORAL QUERIES
-- ============================================================================

-- 1. SPATIAL QUERY: Find restaurants within 500 meters of a customer location
SELECT 
    r.restaurant_name,
    c.customer_name,
    c.hostel_name,
    ROUND(ST_Distance(r.location::geography, c.location::geography)::numeric, 2) AS distance_meters
FROM restaurant r, customer c
WHERE ST_DWithin(r.location::geography, c.location::geography, 500)
ORDER BY distance_meters ASC;

-- 2. TEMPORAL QUERY: Delivery fulfillment duration by hour
SELECT 
    EXTRACT(HOUR FROM created_at) AS order_hour,
    COUNT(order_id) AS total_orders,
    ROUND(AVG(EXTRACT(EPOCH FROM (delivered_at - created_at))/60)::numeric, 2) AS avg_delivery_minutes
FROM delivery_request
WHERE status = 'DELIVERED'
GROUP BY order_hour
ORDER BY order_hour ASC;

-- 3. SPATIOTEMPORAL QUERY: Reconstruct driver trajectory path and calculate distance
SELECT 
    t.delivery_id,
    t.driver_id,
    COUNT(t.trace_id) AS telemetry_ping_count,
    ROUND(ST_Length(ST_MakeLine(t.location ORDER BY t.recorded_at)::geography)::numeric, 2) AS trajectory_length_meters,
    MIN(t.recorded_at) AS trip_start_time,
    MAX(t.recorded_at) AS trip_end_time
FROM location_trace t
GROUP BY t.delivery_id, t.driver_id;

-- 4. ANALYTICAL QUERY: Zone order density and active driver distribution
SELECT 
    z.zone_name,
    COUNT(DISTINCT dr.order_id) AS total_deliveries,
    COUNT(DISTINCT dr.driver_id) AS active_drivers
FROM campus_zone z
JOIN customer c ON ST_Contains(z.boundary, c.location)
JOIN delivery_request dr ON dr.customer_id = c.customer_id
GROUP BY z.zone_id, z.zone_name
ORDER BY total_deliveries DESC;