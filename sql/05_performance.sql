-- ============================================================================
-- MILESTONE 5: INDEXING & PERFORMANCE OPTIMIZATION
-- ============================================================================

-- 1. BENCHMARK SPATIAL INDEX (GiST) vs SEQUENTIAL SCAN
SET enable_seqscan = OFF;
EXPLAIN ANALYZE 
SELECT restaurant_id, restaurant_name 
FROM restaurant 
WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint(77.592, 12.972), 4326), 0.005);

-- 2. BENCHMARK SPATIOTEMPORAL INDEX (BRIN / B-Tree)
EXPLAIN ANALYZE
SELECT driver_id, location, recorded_at
FROM location_trace
WHERE recorded_at BETWEEN '2026-09-12 12:00:00' AND '2026-09-12 13:00:00';

SET enable_seqscan = ON;