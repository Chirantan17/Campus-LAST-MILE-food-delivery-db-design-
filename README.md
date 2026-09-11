# Campus Last-Mile Food Delivery - Spatiotemporal Database Design

A high-performance PostgreSQL + PostGIS spatiotemporal database architecture designed for tracking food orders, delivery drivers, continuous GPS trajectories, and zone-based delivery events across a university campus.

---

## Architecture & Module Summary

### M1: Problem & Workload Analysis
* **Core Goal:** Provide continuous spatiotemporal tracking and dispatching for campus food delivery.
* **Moving Entities:** Delivery Drivers (emitting high-frequency GPS position pings).
* **Static Entities:** Campus Zones (Polygons), Restaurants (Points), Customers (Points).
* **Workload Characteristics:** Write-heavy continuous telemetry streaming (`LOCATION_TRACE`) paired with low-latency spatial proximity reads (`ST_DWithin`)[cite: 1].

### M2: Data & Database Design
* **Spatiotemporal Decoupling:** Decouples high-volume location traces from transactional delivery status updates (`DELIVERY_EVENT`) to prevent database locks[cite: 1].
* **Spatial Indexing:** Uses PostGIS Spatial GiST Indexes (`GIST`) across coordinates and polygons for sub-millisecond query performance[cite: 1].

---

## Entity-Relationship Diagram

```mermaid
erDiagram
    CAMPUS_ZONE ||--o{ CUSTOMER : "contains"
    CAMPUS_ZONE ||--o{ RESTAURANT : "contains"
    CAMPUS_ZONE ||--o{ DELIVERY_EVENT : "contains"
    CUSTOMER ||--o{ ORDER : "places"
    RESTAURANT ||--o{ ORDER : "receives"
    ORDER ||--|| DELIVERY_REQUEST : "creates"
    DRIVER ||--o{ DELIVERY_REQUEST : "assigned_to"
    DRIVER ||--o{ LOCATION_TRACE : "generates"
    DELIVERY_REQUEST ||--o{ LOCATION_TRACE : "tracked_by"
    DELIVERY_REQUEST ||--o{ DELIVERY_EVENT : "has"

    CAMPUS_ZONE {
        int zone_id PK
        string zone_name
        polygon boundary
    }

    CUSTOMER {
        int customer_id PK
        string name
        string phone
        point delivery_location
        int zone_id FK
    }

    RESTAURANT {
        int restaurant_id PK
        string restaurant_name
        point location
        int zone_id FK
        string status
    }

    DRIVER {
        int driver_id PK
        string driver_name
        phone phone
        string vehicle_type
        string status
    }

    ORDER {
        int order_id PK
        int customer_id FK
        int restaurant_id FK
        timestamp order_time
        timestamp promised_delivery_time
        string status
    }

    DELIVERY_REQUEST {
        int delivery_id PK
        int order_id FK
        int driver_id FK
        timestamp assigned_at
        timestamp pickup_time
        timestamp delivery_time
        string status
    }

    LOCATION_TRACE {
        int trace_id PK
        int driver_id FK
        int delivery_id FK
        timestamp timestamp
        point location
    }

    DELIVERY_EVENT {
        int event_id PK
        int delivery_id FK
        int driver_id FK
        string event_type
        timestamp event_time
        point location
    }