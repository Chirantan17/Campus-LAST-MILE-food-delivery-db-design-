import streamlit as st
import pandas as pd
import psycopg2
import folium
from streamlit_folium import st_folium

st.set_page_config(page_title="Campus Spatiotemporal Analytics Engine", layout="wide")

st.title("Campus Last-Mile Delivery Analytics Engine")
st.markdown("Real-time Spatiotemporal Querying, Trajectory Tracking & Geofencing Platform")

@st.cache_resource
def get_db_connection():
    return psycopg2.connect(
        host="127.0.0.1",
        port=5432,
        dbname="campus_delivery",
        user="postgres",
        password="postgrespassword"
    )

try:
    conn = get_db_connection()
    cursor = conn.cursor()

    # Sidebar System Metrics & Filters
    st.sidebar.header("System Dashboard Metrics")
    
    cursor.execute("SELECT COUNT(*) FROM delivery_request;")
    total_orders = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM location_trace;")
    total_telemetry = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM driver;")
    total_drivers = cursor.fetchone()[0]

    st.sidebar.metric("Total Active Orders", total_orders)
    st.sidebar.metric("Telemetry Data Points", total_telemetry)
    st.sidebar.metric("Active Drivers", total_drivers)

    st.sidebar.markdown("---")
    st.sidebar.header("Interactive Map Filters")

    cursor.execute("SELECT driver_id, driver_name FROM driver ORDER BY driver_id;")
    driver_list = cursor.fetchall()
    driver_options = {"All Drivers": None}
    for d_id, d_name in driver_list:
        driver_options[f"Driver #{d_id} - {d_name}"] = d_id

    selected_driver_label = st.sidebar.selectbox("Filter Trajectories by Driver", list(driver_options.keys()))
    selected_driver_id = driver_options[selected_driver_label]

    # Live Geospatial Map View
    st.header("Interactive Campus Map View")

    # Fetch Zones GeoJSON
    cursor.execute("""
        SELECT json_build_object(
            'type', 'FeatureCollection',
            'features', COALESCE(json_agg(ST_AsGeoJSON(z.*)::json), '[]'::json)
        ) FROM (SELECT zone_id, zone_name, boundary FROM campus_zone) z;
    """)
    zone_row = cursor.fetchone()
    zones_json = zone_row[0] if zone_row else None

    # Fetch Trajectories GeoJSON with filter
    if selected_driver_id is None:
        cursor.execute("""
            SELECT json_build_object(
                'type', 'FeatureCollection',
                'features', COALESCE(json_agg(f.feature), '[]'::json)
            ) FROM (
                SELECT json_build_object(
                    'type', 'Feature',
                    'geometry', ST_AsGeoJSON(ST_MakeLine(location ORDER BY recorded_at))::json,
                    'properties', json_build_object('delivery_id', delivery_id, 'driver_id', driver_id)
                ) AS feature
                FROM location_trace 
                GROUP BY delivery_id, driver_id
            ) f;
        """)
    else:
        cursor.execute("""
            SELECT json_build_object(
                'type', 'FeatureCollection',
                'features', COALESCE(json_agg(f.feature), '[]'::json)
            ) FROM (
                SELECT json_build_object(
                    'type', 'Feature',
                    'geometry', ST_AsGeoJSON(ST_MakeLine(location ORDER BY recorded_at))::json,
                    'properties', json_build_object('delivery_id', delivery_id, 'driver_id', driver_id)
                ) AS feature
                FROM location_trace 
                WHERE driver_id = %s
                GROUP BY delivery_id, driver_id
            ) f;
        """, (selected_driver_id,))
    
    traj_row = cursor.fetchone()
    trajectory_json = traj_row[0] if traj_row else None

    m = folium.Map(location=[12.968, 77.592], zoom_start=14, tiles="OpenStreetMap")

    if zones_json and zones_json.get('features'):
        folium.GeoJson(
            zones_json,
            name="Campus Zones",
            style_function=lambda x: {
                'fillColor': '#3186cc',
                'color': '#3186cc',
                'weight': 2,
                'fillOpacity': 0.15
            }
        ).add_to(m)

    if trajectory_json and trajectory_json.get('features'):
        folium.GeoJson(
            trajectory_json,
            name="Driver Trajectories",
            style_function=lambda x: {
                'color': '#8e44ad',
                'weight': 3,
                'opacity': 0.7
            }
        ).add_to(m)

    st_folium(m, width=1100, height=480)

    # Query Execution Tabs
    st.header("Spatiotemporal SQL Query Engine")
    tab1, tab2, tab3 = st.tabs(["M4: Advanced Queries", "M5: Performance Analysis", "M6: Geofence Investigation"])

    with tab1:
        st.subheader("Driver Distance & Trajectory Path Summaries")
        df_m4 = pd.read_sql("""
            SELECT 
                t.delivery_id,
                d.driver_name,
                COUNT(t.trace_id) AS telemetry_pings,
                ROUND(ST_Length(ST_MakeLine(t.location ORDER BY t.recorded_at)::geography)::numeric, 2) AS trajectory_distance_meters,
                MIN(t.recorded_at) AS trip_start,
                MAX(t.recorded_at) AS trip_end
            FROM location_trace t
            JOIN driver d ON t.driver_id = d.driver_id
            GROUP BY t.delivery_id, d.driver_name
            ORDER BY t.delivery_id ASC
            LIMIT 25;
        """, conn)
        st.dataframe(df_m4, use_container_width=True)

    with tab2:
        st.subheader("Spatial Query Optimization (GiST vs Sequential Scan)")
        st.write("Benchmarking PostGIS `ST_DWithin` spatial query execution plan.")
        if st.button("Run EXPLAIN ANALYZE Benchmarks"):
            cursor.execute("""
                EXPLAIN ANALYZE 
                SELECT restaurant_id, restaurant_name 
                FROM restaurant 
                WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint(77.592, 12.972), 4326), 0.005);
            """)
            plan = cursor.fetchall()
            st.code("\n".join([row[0] for row in plan]), language="sql")

    with tab3:
        st.subheader("Geofence Compliance Alerts")
        df_m6 = pd.read_sql("""
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
            ORDER BY t.recorded_at DESC
            LIMIT 30;
        """, conn)
        st.dataframe(df_m6, use_container_width=True)

except Exception as e:
    st.error(f"Error connecting to database or rendering app: {e}")