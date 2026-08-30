# Outbox na borda

Sensor -> fila -> GET /health -> POST /v1/telemetry (lote 25) -> purge.
`TelemetryService.postEvent` enfileira primeiro.
