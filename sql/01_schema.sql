-- Enable PostGIS extension for spatial types
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Campus Zone
CREATE TABLE CAMPUS_ZONE (
    zone_id SERIAL PRIMARY KEY,
    zone_name VARCHAR(100) NOT NULL,
    boundary GEOMETRY(Polygon, 4326) NOT NULL
);

-- 2. Customer
CREATE TABLE CUSTOMER (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    delivery_location GEOMETRY(Point, 4326) NOT NULL,
    zone_id INT REFERENCES CAMPUS_ZONE(zone_id)
);

-- 3. Restaurant
CREATE TABLE RESTAURANT (
    restaurant_id SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(100) NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    zone_id INT REFERENCES CAMPUS_ZONE(zone_id),
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- 4. Driver
CREATE TABLE DRIVER (
    driver_id SERIAL PRIMARY KEY,
    driver_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'AVAILABLE'
);

-- 5. Order
CREATE TABLE "ORDER" (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES CUSTOMER(customer_id),
    restaurant_id INT REFERENCES RESTAURANT(restaurant_id),
    order_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    promised_delivery_time TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) DEFAULT 'PLACED'
);

-- 6. Delivery Request
CREATE TABLE DELIVERY_REQUEST (
    delivery_id SERIAL PRIMARY KEY,
    order_id INT UNIQUE REFERENCES "ORDER"(order_id),
    driver_id INT REFERENCES DRIVER(driver_id),
    assigned_at TIMESTAMPTZ,
    pickup_time TIMESTAMPTZ,
    delivery_time TIMESTAMPTZ,
    status VARCHAR(20) DEFAULT 'CREATED'
);

-- 7. Location Trace
CREATE TABLE LOCATION_TRACE (
    trace_id BIGSERIAL PRIMARY KEY,
    driver_id INT REFERENCES DRIVER(driver_id),
    delivery_id INT REFERENCES DELIVERY_REQUEST(delivery_id),
    recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    location GEOMETRY(Point, 4326) NOT NULL
);

-- 8. Delivery Event
CREATE TABLE DELIVERY_EVENT (
    event_id SERIAL PRIMARY KEY,
    delivery_id INT REFERENCES DELIVERY_REQUEST(delivery_id),
    driver_id INT REFERENCES DRIVER(driver_id),
    event_type VARCHAR(50) NOT NULL,
    event_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    location GEOMETRY(Point, 4326) NOT NULL
);

-- Spatial GiST Indexes
CREATE INDEX idx_campus_zone_boundary ON CAMPUS_ZONE USING GIST(boundary);
CREATE INDEX idx_customer_location ON CUSTOMER USING GIST(delivery_location);
CREATE INDEX idx_restaurant_location ON RESTAURANT USING GIST(location);
CREATE INDEX idx_location_trace_spatial ON LOCATION_TRACE USING GIST(location);
CREATE INDEX idx_location_trace_time ON LOCATION_TRACE(recorded_at);
CREATE INDEX idx_delivery_event_spatial ON DELIVERY_EVENT USING GIST(location);