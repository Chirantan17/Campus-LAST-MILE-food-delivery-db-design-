-- 1. Insert Campus Boundary Polygon (WGS 84 SRID 4326)
INSERT INTO CAMPUS_ZONE (zone_name, boundary) VALUES
('North Campus', ST_GeomFromText('POLYGON((77.5900 12.9700, 77.5950 12.9700, 77.5950 12.9750, 77.5900 12.9750, 77.5900 12.9700))', 4326)),
('South Campus', ST_GeomFromText('POLYGON((77.5900 12.9650, 77.5950 12.9650, 77.5950 12.9700, 77.5900 12.9700, 77.5900 12.9650))', 4326));

-- 2. Insert Sample Restaurants and Customers
INSERT INTO RESTAURANT (restaurant_name, location, zone_id, status) VALUES
('Campus Food Court', ST_SetSRID(ST_MakePoint(77.5925, 12.9725), 4326), 1, 'ACTIVE'),
('Library Cafe', ST_SetSRID(ST_MakePoint(77.5910, 12.9680), 4326), 2, 'ACTIVE');

INSERT INTO CUSTOMER (name, phone, delivery_location, zone_id) VALUES
('Alice Smith', '9876543210', ST_SetSRID(ST_MakePoint(77.5940, 12.9740), 4326), 1),
('Bob Jones', '9876543211', ST_SetSRID(ST_MakePoint(77.5915, 12.9670), 4326), 2);

-- 3. Insert Drivers
INSERT INTO DRIVER (driver_name, phone, vehicle_type, status) VALUES
('Rider 1', '9000000001', 'E-Bike', 'AVAILABLE'),
('Rider 2', '9000000002', 'Bicycle', 'BUSY');

-- 4. Insert Order and Delivery Request
INSERT INTO "ORDER" (customer_id, restaurant_id, order_time, promised_delivery_time, status) VALUES
(1, 1, NOW() - INTERVAL '30 minutes', NOW() + INTERVAL '10 minutes', 'DISPATCHED');

INSERT INTO DELIVERY_REQUEST (order_id, driver_id, assigned_at, status) VALUES
(1, 1, NOW() - INTERVAL '25 minutes', 'IN_TRANSIT');

-- 5. Insert Continuous Driver Location Telemetry
INSERT INTO LOCATION_TRACE (driver_id, delivery_id, recorded_at, location) VALUES
(1, 1, NOW() - INTERVAL '20 minutes', ST_SetSRID(ST_MakePoint(77.5925, 12.9725), 4326)),
(1, 1, NOW() - INTERVAL '15 minutes', ST_SetSRID(ST_MakePoint(77.5930, 12.9730), 4326)),
(1, 1, NOW() - INTERVAL '10 minutes', ST_SetSRID(ST_MakePoint(77.5935, 12.9735), 4326)),
(1, 1, NOW() - INTERVAL '5 minutes',  ST_SetSRID(ST_MakePoint(77.5940, 12.9740), 4326));

-- 6. Insert Delivery Milestones
INSERT INTO DELIVERY_EVENT (delivery_id, driver_id, event_type, event_time, location) VALUES
(1, 1, 'ASSIGNED', NOW() - INTERVAL '25 minutes', ST_SetSRID(ST_MakePoint(77.5925, 12.9725), 4326)),
(1, 1, 'PICKUP',   NOW() - INTERVAL '20 minutes', ST_SetSRID(ST_MakePoint(77.5925, 12.9725), 4326)),
(1, 1, 'DELIVERED', NOW() - INTERVAL '2 minutes',  ST_SetSRID(ST_MakePoint(77.5940, 12.9740), 4326));