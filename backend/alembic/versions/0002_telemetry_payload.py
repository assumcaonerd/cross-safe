"""Add edge telemetry fields used by mobile and municipal scoring.

Revision ID: 0002_telemetry_payload
Revises: 0001_initial_spatial
"""

from alembic import op

revision = "0002_telemetry_payload"
down_revision = "0001_initial_spatial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute(
        """
        ALTER TABLE incident_telemetry
            ADD COLUMN IF NOT EXISTS distance_m DOUBLE PRECISION,
            ADD COLUMN IF NOT EXISTS respect_score INTEGER,
            ADD COLUMN IF NOT EXISTS screen_active BOOLEAN,
            ADD COLUMN IF NOT EXISTS mode_confidence DOUBLE PRECISION,
            ADD COLUMN IF NOT EXISTS source VARCHAR(24) DEFAULT 'in_app',
            ADD COLUMN IF NOT EXISTS city VARCHAR(80) DEFAULT 'Vitoria',
            ADD COLUMN IF NOT EXISTS features_json TEXT
        """
    )
    op.execute("UPDATE incident_telemetry SET source = 'in_app' WHERE source IS NULL")
    op.execute("UPDATE incident_telemetry SET city = 'Vitoria' WHERE city IS NULL")
    op.execute("ALTER TABLE incident_telemetry ALTER COLUMN source SET NOT NULL")
    op.execute("ALTER TABLE incident_telemetry ALTER COLUMN city SET NOT NULL")


def downgrade() -> None:
    op.execute(
        """
        ALTER TABLE incident_telemetry
            DROP COLUMN IF EXISTS features_json,
            DROP COLUMN IF EXISTS city,
            DROP COLUMN IF EXISTS source,
            DROP COLUMN IF EXISTS mode_confidence,
            DROP COLUMN IF EXISTS screen_active,
            DROP COLUMN IF EXISTS respect_score,
            DROP COLUMN IF EXISTS distance_m
        """
    )
