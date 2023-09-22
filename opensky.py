import psycopg2
from opensky_api import OpenSkyApi
import time

# Connect BD
conn = psycopg2.connect(
    dbname='opensky',
    user='postgres',
    password='admin',
    host='localhost',
    port='5433'
)

cur = conn.cursor()

# Connect OpenSkyApi
api = OpenSkyApi('username', 'password')

try:
    while True:
        states = api.get_states()

        if states is not None:

            # Insert Insertion
            cur.execute("INSERT INTO insertion (date_insertion) VALUES (NOW()) RETURNING id_insertion")
            insertion_id = cur.fetchone()[0]

            # Flight treatments
            aeronefs_data = []
            for i in states.states:
                aeronefs_data.append((i.icao24, i.callsign, i.category, i.origin_country, i.latitude, i.longitude,
                                     i.baro_altitude, i.geo_altitude, i.velocity, i.vertical_rate, i.time_position, insertion_id))
                
            # Insert aircrafts
            cur.executemany("""INSERT INTO aeronefs (icao24, callsign, category, origin_country, latitude, longitude, baro_altitude, geo_altitude, velocity, vertical_rate, time_position, id_insertion) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, to_timestamp(%s), %s)""", aeronefs_data)
            conn.commit()

            print("\nNombre d'aéronefs: ", len(states.states))

        time.sleep(30)

except KeyboardInterrupt:
    print("Arrêt de l'execution")

cur.close()
conn.close()