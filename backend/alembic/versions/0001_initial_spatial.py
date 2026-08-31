"""Initial PostGIS schema and ES crosswalk seed.

Revision ID: 0001_initial_spatial
Revises:
"""

from alembic import op

revision = "0001_initial_spatial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS crosswalks (
            id SERIAL PRIMARY KEY,
            name VARCHAR(160) NOT NULL,
            city VARCHAR(80) NOT NULL DEFAULT 'Vitoria',
            state CHAR(2) NOT NULL DEFAULT 'ES',
            risk_score DOUBLE PRECISION NOT NULL DEFAULT 0,
            location GEOGRAPHY(POINT, 4326) NOT NULL,
            notes TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS idx_crosswalks_location "
        "ON crosswalks USING GIST (location)"
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS municipal_zones (
            id SERIAL PRIMARY KEY,
            name VARCHAR(160) NOT NULL,
            zone_type VARCHAR(40) NOT NULL,
            priority INTEGER NOT NULL DEFAULT 2,
            geom GEOGRAPHY(POLYGON, 4326) NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS idx_zones_geom "
        "ON municipal_zones USING GIST (geom)"
    )
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS incident_telemetry (
            id SERIAL PRIMARY KEY,
            transport_mode VARCHAR(32) NOT NULL,
            event_type VARCHAR(40) NOT NULL,
            speed_mps DOUBLE PRECISION,
            deceleration_mps2 DOUBLE PRECISION,
            location GEOGRAPHY(POINT, 4326) NOT NULL,
            crosswalk_id INTEGER REFERENCES crosswalks(id),
            recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    op.execute(
        "CREATE INDEX IF NOT EXISTS idx_telemetry_location "
        "ON incident_telemetry USING GIST (location)"
    )
    op.execute(
        """
        INSERT INTO crosswalks (name, city, state, risk_score, location, notes)
        SELECT seed.name, seed.city, seed.state, seed.risk_score,
               ST_GeogFromText(seed.location), seed.notes
        FROM (VALUES
            ('Av. Dante Michelini x Camburi', 'Vitoria', 'ES', 0.72,
             'SRID=4326;POINT(-40.2856 -20.2825)',
             'Orla de Camburi, fluxo alto de pedestres e veiculos'),
            ('Terceira Ponte - acesso Vila Velha', 'Vila Velha', 'ES', 0.81,
             'SRID=4326;POINT(-40.3160 -20.3278)',
             'Aproximacao rapida, janela de alerta maior'),
            ('Av. Eldes Scherrer Souza x Laranjeiras', 'Serra', 'ES', 0.64,
             'SRID=4326;POINT(-40.2260 -20.1965)',
             'Corredor escolar e comercial')
        ) AS seed(name, city, state, risk_score, location, notes)
        WHERE NOT EXISTS (
            SELECT 1 FROM crosswalks existing WHERE existing.name = seed.name
        )
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS incident_telemetry")
    op.execute("DROP TABLE IF EXISTS municipal_zones")
    op.execute("DROP TABLE IF EXISTS crosswalks")
