# Campus-LAST-MILE-food-delivery-db-design-
Spatiotemporal database and architecture for campus last-mile food delivery
# Campus Last-Mile Food Delivery - Spatiotemporal Database Design

A high-performance PostgreSQL + PostGIS spatiotemporal database architecture designed for tracking food orders, delivery drivers, continuous GPS trajectories, and zone-based delivery events across a university campus[cite: 1].

---

## Architecture & Module Summary

### M1: Problem & Workload Analysis
* **Core Goal:** Provide continuous spatiotemporal tracking and dispatching for campus food delivery[cite: 1].
* **Moving Entities:** Delivery Drivers (emitting high-frequency GPS position pings)[cite: 1].
* **Static Entities:** Campus Zones (Polygons), Restaurants (Points), Customers (Points)[cite: 1].
* **Workload Characteristics:** Write-heavy continuous telemetry streaming (`LOCATION_TRACE`) paired with low-latency spatial proximity reads (`ST_DWithin`)[cite: 1].

### M2: Data & Database Design
* **Spatiotemporal Decoupling:** Decouples high-volume location traces from transactional delivery status updates (`DELIVERY_EVENT`) to prevent database locks[cite: 1].
* **Spatial Indexing:** Uses PostGIS Spatial GiST Indexes (`GIST`) across coordinates and polygons for sub-millisecond query performance[cite: 1].

---

## Database Schema & ER Diagram