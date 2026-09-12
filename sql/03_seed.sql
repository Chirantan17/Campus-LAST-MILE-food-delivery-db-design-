-- Reset table contents
TRUNCATE TABLE delivery_event, location_trace, delivery_request, customer, restaurant, driver, campus_zone RESTART IDENTITY CASCADE;

-- 1. Campus Zones
INSERT INTO campus_zone (zone_name, boundary) VALUES
('North Campus', ST_GeomFromText('POLYGON((77.590 12.970, 77.595 12.970, 77.595 12.975, 77.590 12.975, 77.590 12.970))', 4326)),
('South Campus', ST_GeomFromText('POLYGON((77.590 12.965, 77.595 12.965, 77.595 12.970, 77.590 12.970, 77.590 12.965))', 4326));

-- 2. Drivers
INSERT INTO driver (driver_name, phone, status) VALUES
('John Doe', '9876543210', 'BUSY'),
('Jane Smith', '9876543211', 'AVAILABLE');

-- 3. Restaurants
INSERT INTO restaurant (restaurant_name, location) VALUES
('Campus Canteen', ST_SetSRID(ST_MakePoint(77.592, 12.972), 4326)),
('North Food Court', ST_SetSRID(ST_MakePoint(77.594, 12.974), 4326));

-- 4. Customers / Hostels
INSERT INTO customer (customer_name, hostel_name, location) VALUES
('Alice Johnson', 'Hostel A', ST_SetSRID(ST_MakePoint(77.593, 12.973), 4326)),
('Bob Williams', 'Hostel B', ST_SetSRID(ST_MakePoint(77.591, 12.968), 4326));

-- 5. Delivery Requests / Orders
INSERT INTO delivery_request (customer_id, restaurant_id, driver_id, status, created_at, delivered_at) VALUES
(1, 1, 1, 'DELIVERED', '2026-09-12 12:00:00', '2026-09-12 12:25:00'),
(2, 2, 2, 'IN_TRANSIT', '2026-09-12 12:30:00', NULL);

-- 6. Location Telemetry Trajectories
INSERT INTO location_trace (delivery_id, driver_id, location, recorded_at) VALUES
(1, 1, ST_SetSRID(ST_MakePoint(77.5925, 12.9725), 4326), '2026-09-12 12:05:00'),
(1, 1, ST_SetSRID(ST_MakePoint(77.5930, 12.9730), 4326), '2026-09-12 12:10:00'),
(1, 1, ST_SetSRID(ST_MakePoint(77.5935, 12.9735), 4326), '2026-09-12 12:15:00'),
(1, 1, ST_SetSRID(ST_MakePoint(77.5940, 12.9740), 4326), '2026-09-12 12:20:00');