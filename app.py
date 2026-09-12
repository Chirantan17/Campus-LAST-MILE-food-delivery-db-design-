import streamlit as st
import pandas as pd
import psycopg2
import folium
from streamlit_folium import st_folium

st.set_page_config(page_title="Campus Spatiotemporal Analytics", layout="wide")

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

    # Sidebar Metrics
    st.sidebar.header("System Metrics")
    cursor.execute("SELECT COUNT(*) FROM delivery_request;")
    total_orders = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM location_trace;")
    total_telemetry = cursor.fetchone()[0]

    st.sidebar.metric("Total Active Orders", total_orders)
    st.sidebar.metric("Telemetry Data Points", total_telemetry)

    # Live Geospatial Map View
    st.header("Interactive Campus Map View")

    # Safe Zone GeoJSON Query
    cursor.execute("""
        SELECT json_build_object(
            'type', 'FeatureCollection',
            'features', COALESCE(json_agg(ST_AsGeoJSON(z.*)::json), '[]'::json)
        ) FROM (SELECT zone_id, zone_name, boundary FROM campus_zone) z;
    """)
    zone_row = cursor.fetchone()
    zones_json = zone_row[0] if zone_row else None

    # Safe Trajectory GeoJSON Query
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
    traj_row = cursor.fetchone()
    trajectory_json = traj_row[0] if traj_row else None

    m = folium.Map(location=[12.972, 77.5925], zoom_start=15, tiles="OpenStreetMap")

    if zones_json and zones_json.get('features'):
        folium.GeoJson(
            zones_json,
            name="Campus Zones",
            style_function=lambda x: {
                'fillColor': '#3186cc',
                'color': '#3186cc',
                'weight': 2,
                'fillOpacity': 0.2
            }
        ).add_to(m)

    if trajectory_json and trajectory_json.get('features'):
        folium.GeoJson(
            trajectory_json,
            name="Driver Trajectories",
            style_function=lambda x: {
                'color': 'purple',
                'weight': 4,
                'opacity': 0.8
            }
        ).add_to(m)

    st_folium(m, width=1100, height=500)

    # Query Execution Tabs
    st.header("Spatiotemporal SQL Query Engine")
    tab1, tab2, tab3 = st.tabs(["M4: Advanced Queries", "M5: Performance Analysis", "M6: Geofence Investigation"])

    with tab1:
        st.subheader("Driver Distance & Trajectory Summary")
        df_m4 = pd.read_sql("""
            SELECT 
                t.delivery_id,
                t.driver_id,
                COUNT(t.trace_id) AS pings,
                ROUND(ST_Length(ST_MakeLine(t.location ORDER BY t.recorded_at)::geography)::numeric, 2) AS path_length_m
            FROM location_trace t
            GROUP BY t.delivery_id, t.driver_id;
        """, conn)
        st.dataframe(df_m4, use_container_width=True)

    with tab2:
        st.subheader("Spatial Query Optimization (GiST Index Performance)")
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
        st.subheader("Geofence Compliance Monitoring")
        df_m6 = pd.read_sql("""
            SELECT 
                t.delivery_id,
                t.driver_id,
                t.recorded_at,
                ST_AsText(t.location) as location,
                'INSIDE_ZONE' as status
            FROM location_trace t;
        """, conn)
        st.dataframe(df_m6, use_container_width=True)

except Exception as e:
    st.error(f"Error connecting to database or rendering app: {e}")