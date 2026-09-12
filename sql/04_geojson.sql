-- Export Campus Zones as a GeoJSON FeatureCollection
SELECT json_build_object(
    'type', 'FeatureCollection',
    'features', json_agg(
        json_build_object(
            'type', 'Feature',
            'geometry', ST_AsGeoJSON(boundary)::json,
            'properties', json_build_object('zone_id', zone_id, 'zone_name', zone_name)
        )
    )
) FROM CAMPUS_ZONE;

-- Export Driver Trajectory Line as GeoJSON
SELECT json_build_object(
    'type', 'Feature',
    'geometry', ST_AsGeoJSON(ST_MakeLine(location ORDER BY recorded_at))::json,
    'properties', json_build_object('delivery_id', delivery_id, 'driver_id', driver_id)
)
FROM LOCATION_TRACE
WHERE delivery_id = 1
GROUP BY delivery_id, driver_id;