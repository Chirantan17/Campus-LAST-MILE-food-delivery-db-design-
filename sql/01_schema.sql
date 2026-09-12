-- Reset database schema for clean automated runs
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Campus Zones Table
CREATE TABLE campus_zone (
    zone_id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    boundary GEOMETRY(Polygon, 4326) NOT NULL
);

-- 2. Drivers Table
CREATE TABLE driver (
    driver_id SERIAL PRIMARY KEY,
    driver_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    status VARCHAR(20) DEFAULT 'AVAILABLE'
);

-- 3. Restaurants Table
CREATE TABLE restaurant (
    restaurant_id SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL
);

-- 4. Customers / Hostels Table
CREATE TABLE customer (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    hostel_name VARCHAR(100),
    location GEOMETRY(Point, 4326) NOT NULL
);

-- 5. Delivery Requests / Orders Table
CREATE TABLE delivery_request (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    restaurant_id INT REFERENCES restaurant(restaurant_id),
    driver_id INT REFERENCES driver(driver_id),
    status VARCHAR(30) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivered_at TIMESTAMP
);

-- 6. Location Telemetry Trajectories Table
CREATE TABLE location_trace (
    trace_id SERIAL PRIMARY KEY,
    delivery_id INT REFERENCES delivery_request(order_id),
    driver_id INT REFERENCES driver(driver_id),
    location GEOMETRY(Point, 4326) NOT NULL,
    recorded_at TIMESTAMP NOT NULL
);

-- 7. Delivery Events Table
CREATE TABLE delivery_event (
    event_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES delivery_request(order_id),
    event_type VARCHAR(50) NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- SPATIAL INDEXES (GiST)
CREATE INDEX idx_campus_zone_boundary ON campus_zone USING GIST (boundary);
CREATE INDEX idx_customer_location ON customer USING GIST (location);
CREATE INDEX idx_restaurant_location ON restaurant USING GIST (location);
CREATE INDEX idx_location_trace_spatial ON location_trace USING GIST (location);
CREATE INDEX idx_delivery_event_spatial ON delivery_event USING GIST (location);

-- TEMPORAL INDEXES (B-Tree & BRIN)
CREATE INDEX idx_location_trace_time ON location_trace (recorded_at);
CREATE INDEX idx_location_trace_brin_time ON location_trace USING BRIN (recorded_at);