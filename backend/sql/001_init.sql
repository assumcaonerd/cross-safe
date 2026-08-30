CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS crosswalks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(160) NOT NULL,
    city VARCHAR(80) NOT NULL DEFAULT 'Vitória',
    state CHAR(2) NOT NULL DEFAULT 'ES',
    risk_score DOUBLE PRECISION NOT NULL DEFAULT 0,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_crosswalks_location ON crosswalks USING GIST (location);

CREATE TABLE IF NOT EXISTS municipal_zones (
    id SERIAL PRIMARY KEY,
    name VARCHAR(160) NOT NULL,
    zone_type VARCHAR(40) NOT NULL,
    priority INTEGER NOT NULL DEFAULT 2,
    geom GEOGRAPHY(POLYGON, 4326) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_zones_geom ON municipal_zones USING GIST (geom);

CREATE TABLE IF NOT EXISTS incident_telemetry (
    id SERIAL PRIMARY KEY,
    transport_mode VARCHAR(32) NOT NULL,
    event_type VARCHAR(40) NOT NULL,
    speed_mps DOUBLE PRECISION,
    deceleration_mps2 DOUBLE PRECISION,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    crosswalk_id INTEGER REFERENCES crosswalks(id),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_telemetry_location ON incident_telemetry USING GIST (location);

INSERT INTO crosswalks (name, city, state, risk_score, location, notes) VALUES
(
    'Av. Dante Michelini x Camburi',
    'Vitória',
    'ES',
    0.72,
    ST_GeogFromText('SRID=4326;POINT(-40.2856 -20.2825)'),
    'Orla de Camburi, fluxo alto de pedestres e veículos'
),
(
    'Terceira Ponte - acesso Vila Velha',
    'Vila Velha',
    'ES',
    0.81,
    ST_GeogFromText('SRID=4326;POINT(-40.3160 -20.3278)'),
    'Aproximação rápida, janela de alerta maior'
),
(
    'Av. Eldes Scherrer Souza x Laranjeiras',
    'Serra',
    'ES',
    0.64,
    ST_GeogFromText('SRID=4326;POINT(-40.2260 -20.1965)'),
    'Corredor escolar e comercial'
);
