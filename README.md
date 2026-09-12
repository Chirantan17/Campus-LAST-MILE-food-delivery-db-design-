# Campus Last-Mile Food Delivery - Spatiotemporal Database & Analytics Engine

[![Streamlit App](https://static.streamlit.io/badges/streamlit_badge_black_white.svg)](https://last-mile-campus-delivery-chirantan.streamlit.app)
[![PostGIS Engine](https://img.shields.io/badge/PostGIS-Spatiotemporal%20Engine-blue?style=flat&logo=postgresql)](https://github.com/Chirantan17/Campus-LAST-MILE-food-delivery-db-design)
[![Database](https://img.shields.io/badge/Database-Neon%20PostgreSQL-00E599?style=flat&logo=postgresql&logoColor=white)](https://neon.tech)
[![Python 3.10+](https://img.shields.io/badge/Python-3.10%2B-3776AB?style=flat&logo=python&logoColor=white)](https://www.python.org/)

A high-performance PostgreSQL + PostGIS spatiotemporal database architecture and interactive analytics dashboard designed for real-time food order tracking, driver trajectory reconstruction, spatial index benchmarking, and automated geofence compliance monitoring across a university campus.

---

### 🚀 [Launch Live Interactive Dashboard](https://last-mile-campus-delivery-chirantan.streamlit.app)

---

## Tech Stack & Architecture

* **Database Engine:** PostgreSQL + PostGIS (Hosted on Neon Cloud)
* **Spatial Functions:** `ST_Contains`, `ST_MakeLine`, `ST_Length`, `ST_DWithin`, `ST_AsGeoJSON`
* **Indexing:** PostGIS Spatial GiST (`GIST`) indexing for sub-millisecond query performance
* **Dashboard & Visualizations:** Streamlit, Folium / Leaflet JS, Pandas, Psycopg2
* **Data Pipeline:** Synthetic spatiotemporal telemetry generator with linear interpolation & simulated anomalies

---

## Architecture & Module Summary

### M1: Problem & Workload Analysis
* **Core Goal:** Continuous spatiotemporal tracking and dispatching for campus food delivery.
* **Moving Entities:** Delivery Drivers (emitting high-frequency GPS position pings).
* **Static Entities:** Campus Zones (`POLYGON`), Restaurants (`POINT`), Hostels/Customers (`POINT`).
* **Workload Characteristics:** Write-heavy continuous telemetry streaming (`location_trace`) paired with low-latency spatial proximity reads (`ST_DWithin`).

### M2: Data & Database Design
* **Spatiotemporal Decoupling:** Decouples high-volume location traces from transactional delivery status updates (`delivery_event`) to prevent database lock contention.
* **Spatial Indexing:** Employs PostGIS Spatial GiST Indexes (`GIST`) across coordinates and polygons for sub-millisecond query performance.

### M3: Synthetic Telemetry Generator
* **Data Pipeline:** Python generation script (`generate_data.py`) populating 60+ active orders, campus zone polygons, and over 600 interpolated GPS trajectory pings with simulated geofence anomalies.

### M4: Spatiotemporal Query Engine
* **Trajectory Reconstruction:** Dynamically generates driver paths and calculates real-time distance metrics using PostGIS spatial functions (`ST_MakeLine`, `ST_Length`).

### M5: Performance Analysis & Spatial Optimization
* **Index Benchmarking:** Uses `EXPLAIN ANALYZE` inside the dashboard to evaluate PostGIS GiST index traversal performance versus sequential scans.

### M6: Geofence Investigation & Compliance
* **Real-time Boundary Checking:** Performs spatial containment checks (`ST_Contains`) between active driver telemetry points and target campus zones to trigger immediate visual geofence breach alerts on live Leaflet map overlays.

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