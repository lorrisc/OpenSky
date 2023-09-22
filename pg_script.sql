CREATE TABLE insertion(
   id_insertion SERIAL,
   date_insertion TIMESTAMP DEFAULT NOW(),
   PRIMARY KEY(id_insertion)
);

CREATE TABLE aeronefs(
   id_aeronefs BIGSERIAL,
   icao24 VARCHAR(20),
   callsign VARCHAR(15),
   category INT,
   origin_country VARCHAR(100),
   latitude DECIMAL(7,4),
   longitude DECIMAL(7,4),
   baro_altitude DECIMAL(7,2),
   geo_altitude DECIMAL(7,2),
   velocity DECIMAL(6,2),
   vertical_rate DECIMAL(5,2),
   time_position TIMESTAMP,
   id_insertion INT NOT NULL,
   PRIMARY KEY(id_aeronefs),
   FOREIGN KEY(id_insertion) REFERENCES insertion(id_insertion)
);

CREATE TABLE category(
   id_category INT,
   lib_category VARCHAR(200),
   PRIMARY KEY(id_category)
);

INSERT INTO category(id_category, lib_category)
VALUES
(0,'Aucune information'),
(1,'Aucune information sur l émetteur ADS-B'),
(2,'Léger | < 7 t'),
(3,'Taille moyenne | de 7 à 34 t'),
(4,'Grande taille | de 34 à 136 t'),
(5,'Grande envergure'),
(6,'Lourd | > 136 t'),
(7,'Performant | > 5g et > 400 noeuds'),
(8,'Hélicoptère'),
(9,'Planeur'),
(10,'Plus léger que l air'),
(11,'Parachutiste'),
(12,'Ultra-léger'),
(13,'Reserved'),
(14,'Drone'),
(15,'Véhicule transatmosphérique'),
(16,'Véhicule d urgence'),
(17,'Véhicule de service'),
(18,'Obstacle ponctuel (ballon captif)'),
(19,'Groupe d obstacle'),
(20,'Obstacle en ligne');

CREATE INDEX idx_icao24 ON aeronefs (icao24);
CREATE INDEX idx_lat ON aeronefs (latitude);
CREATE INDEX idx_lon ON aeronefs (longitude);
CREATE INDEX idx_id_insertion ON aeronefs (id_insertion);
CREATE INDEX idx_time_position ON aeronefs (time_position);

CREATE OR REPLACE FUNCTION get_aeronefs_by_category(grafana text)
RETURNS TABLE (icao24 varchar(20), latitude DECIMAL(7,4), longitude DECIMAL(7,4))
AS $$
BEGIN
    IF grafana = 'ALL' THEN
        RETURN QUERY
        SELECT a.icao24, a.latitude, a.longitude
        FROM aeronefs a
        WHERE a.id_insertion = (SELECT MAX(id_insertion) FROM aeronefs)
        AND a.latitude IS NOT NULL
        AND a.longitude IS NOT NULL;
    ELSE
        RETURN QUERY
        SELECT a.icao24, a.latitude, a.longitude
        FROM aeronefs a
        WHERE a.id_insertion = (SELECT MAX(id_insertion) FROM aeronefs)
        AND a.latitude IS NOT NULL
        AND a.longitude IS NOT NULL
        AND a.category IN (
            SELECT id_category
            FROM category
            WHERE lib_category = ANY(string_to_array(grafana, ','))
        );
    END IF;
END;
$$
LANGUAGE plpgsql;