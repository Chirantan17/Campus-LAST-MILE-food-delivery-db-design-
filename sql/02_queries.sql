-- 1. Spatial Query: Find 5 nearest available drivers within 2km of a restaurant
SELECT 
    d.driver_id, 
    d.driver_name, 
    ST_Distance(lt.location::geography, r.location::geography) AS distance_meters
FROM DRIVER d
JOIN LOCATION_TRACE lt ON d.driver_id = lt.driver_id
JOIN RESTAURANT r ON r.restaurant_id = 1
WHERE d.status = 'AVAILABLE'
  AND ST_DWithin(lt.location::geography, r.location::geography, 2000)
ORDER BY distance_meters ASC
LIMIT 5;

-- 2. Spatiotemporal Query: Reconstruct a delivery driver's full route trajectory line
SELECT 
    delivery_id, 
    ST_MakeLine(location ORDER BY recorded_at) AS trajectory_line
FROM LOCATION_TRACE
WHERE delivery_id = 1
GROUP BY delivery_id;

-- 3. Temporal Query: Detect delayed deliveries exceeding promised delivery window
SELECT 
    o.order_id, 
    dr.delivery_id, 
    o.promised_delivery_time, 
    dr.delivery_time,
    EXTRACT(EPOCH FROM (dr.delivery_time - o.promised_delivery_time))/60 AS delay_minutes
FROM "ORDER" o
JOIN DELIVERY_REQUEST dr ON o.order_id = dr.order_id
WHERE dr.delivery_time > o.promised_delivery_time;

-- 4. Spatiotemporal Aggregate: Deliveries completed per Campus Zone by hour
SELECT 
    z.zone_name, 
    DATE_PART('hour', de.event_time) AS delivery_hour, 
    COUNT(de.event_id) AS total_completed
FROM DELIVERY_EVENT de
JOIN CAMPUS_ZONE z ON ST_Contains(z.boundary, de.location)
WHERE de.event_type = 'DELIVERED'
GROUP BY z.zone_name, delivery_hour
ORDER BY z.zone_name, delivery_hour;