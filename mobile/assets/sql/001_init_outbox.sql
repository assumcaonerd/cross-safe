CREATE TABLE IF NOT EXISTS pending_telemetry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    payload TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_pending_telemetry_timestamp ON pending_telemetry(timestamp);
