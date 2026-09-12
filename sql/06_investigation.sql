-- ============================================================================
-- MILESTONE 6: CUSTOM INVESTIGATION (GEOFENCE & BOTTLENECK ANALYSIS)
-- ============================================================================

-- INVESTIGATION: Detect telemetry points where drivers breached assigned zones
WITH ActiveDeliveryZones AS (
    SELECT 
        dr.order_id,
        dr.driver_id,
        z.zone_name,
        z.boundary
    FROM delivery_request dr
    JOIN customer c ON dr.customer_id = c.customer_id
    JOIN campus_zone z ON ST_Contains(z.boundary, c.location)
)
SELECT 
    t.delivery_id,
    t.driver_id,
    adz.zone_name AS assigned_zone,
    t.recorded_at AS breach_timestamp,
    ST_AsText(t.location) AS breach_coordinates,
    CASE 
        WHEN ST_Contains(adz.boundary, t.location) THEN 'INSIDE_ZONE'
        ELSE 'GEOFENCE_BREACH_ALERT'
    END AS spatial_status
FROM location_trace t
JOIN ActiveDeliveryZones adz ON t.delivery_id = adz.order_id
ORDER BY t.recorded_at ASC;