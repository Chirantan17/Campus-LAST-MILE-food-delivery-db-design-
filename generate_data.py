import psycopg2
import random
from datetime import datetime, timedelta

def populate_database():
    conn = psycopg2.connect(
        host="127.0.0.1",
        port=5432,
        dbname="campus_delivery",
        user="postgres",
        password="postgrespassword"
    )
    cursor = conn.cursor()

    print("Cleaning existing database tables...")
    cursor.execute("TRUNCATE TABLE delivery_event, location_trace, delivery_request, customer, restaurant, driver, campus_zone RESTART IDENTITY CASCADE;")

    print("Seeding campus zones...")
    cursor.execute("""
        INSERT INTO campus_zone (zone_name, boundary) VALUES
        ('North Academic Zone', ST_GeomFromText('POLYGON((77.588 12.968, 77.596 12.968, 77.596 12.976, 77.588 12.976, 77.588 12.968))', 4326)),
        ('South Hostel Zone', ST_GeomFromText('POLYGON((77.588 12.960, 77.596 12.960, 77.596 12.968, 77.588 12.968, 77.588 12.960))', 4326));
    """)

    print("Seeding active drivers...")
    drivers = [
        ("Alex Rivera", "9876543210", "BUSY"),
        ("Sam Taylor", "9876543211", "AVAILABLE"),
        ("Jordan Lee", "9876543212", "BUSY"),
        ("Morgan Chen", "9876543213", "AVAILABLE")
    ]
    for name, phone, status in drivers:
        cursor.execute("INSERT INTO driver (driver_name, phone, status) VALUES (%s, %s, %s);", (name, phone, status))

    print("Seeding campus restaurants...")
    restaurants = [
        ("Central Canteen", 77.5920, 12.9730),
        ("Tech Park Food Court", 77.5945, 12.9715),
        ("North Library Cafe", 77.5905, 12.9745)
    ]
    for name, lon, lat in restaurants:
        cursor.execute("INSERT INTO restaurant (restaurant_name, location) VALUES (%s, ST_SetSRID(ST_MakePoint(%s, %s), 4326));", (name, lon, lat))

    print("Seeding hostel customer drop-offs...")
    hostels = [
        ("Alice Green", "Hostel Block A", 77.5910, 12.9650),
        ("Bob Miller", "Hostel Block B", 77.5940, 12.9635),
        ("Charlie Davis", "PG Heights", 77.5895, 12.9620),
        ("Diana Prince", "Research Scholars Hostel", 77.5955, 12.9660)
    ]
    for name, hostel, lon, lat in hostels:
        cursor.execute("INSERT INTO customer (customer_name, hostel_name, location) VALUES (%s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326));", (name, hostel, lon, lat))

    print("Generating 60 orders and 600+ spatiotemporal telemetry pings...")
    base_time = datetime(2026, 9, 12, 8, 0, 0)

    for order_id in range(1, 61):
        cust_id = random.randint(1, len(hostels))
        rest_id = random.randint(1, len(restaurants))
        driver_id = random.randint(1, len(drivers))

        created = base_time + timedelta(minutes=random.randint(1, 480))
        delivered = created + timedelta(minutes=random.randint(12, 35))
        status = 'DELIVERED' if random.random() > 0.15 else 'IN_TRANSIT'

        cursor.execute("""
            INSERT INTO delivery_request (customer_id, restaurant_id, driver_id, status, created_at, delivered_at)
            VALUES (%s, %s, %s, %s, %s, %s);
        """, (cust_id, rest_id, driver_id, status, created, delivered if status == 'DELIVERED' else None))

        # Get restaurant start coordinates
        cursor.execute("SELECT ST_X(location), ST_Y(location) FROM restaurant WHERE restaurant_id = %s;", (rest_id,))
        start_lon, start_lat = cursor.fetchone()

        # Get customer destination coordinates
        cursor.execute("SELECT ST_X(location), ST_Y(location) FROM customer WHERE customer_id = %s;", (cust_id,))
        end_lon, end_lat = cursor.fetchone()

        # Generate 10 trajectory pings along interpolated path
        num_pings = 10
        for step in range(num_pings):
            fraction = step / (num_pings - 1)
            ping_lon = start_lon + fraction * (end_lon - start_lon) + random.uniform(-0.0003, 0.0003)
            ping_lat = start_lat + fraction * (end_lat - start_lat) + random.uniform(-0.0003, 0.0003)

            # Inject occasional geofence breach points for M6 analysis
            if step == 5 and random.random() < 0.2:
                ping_lon += 0.012

            ping_time = created + timedelta(minutes=step * 2)

            cursor.execute("""
                INSERT INTO location_trace (delivery_id, driver_id, location, recorded_at)
                VALUES (%s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326), %s);
            """, (order_id, driver_id, ping_lon, ping_lat, ping_time))

    conn.commit()
    cursor.close()
    conn.close()
    print(" Database fully populated with 60 orders & 600 telemetry points!")

if __name__ == "__main__":
    populate_database()