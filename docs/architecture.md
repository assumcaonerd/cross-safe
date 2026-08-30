# Arquitetura inicial

```
[Flutter edge] --GPS/IMU--> classificação local
        |                      |
        | HTTP                 | hard-brake / modo
        v                      v
[FastAPI + PostGIS] <---- incident_telemetry
        |
        +-- crosswalks (faixas)
        +-- municipal_zones (escolas, hospitais)
        +-- /v1/crosswalks/nearby?lat&lon&speed_mps
```

## Issue 1

PostgreSQL + PostGIS, tabelas geográficas e endpoints REST de injeção e busca
por raio. O raio cresce com a distância de frenagem.

## Issue 2

App Flutter com permissão de localização, stream GPS e haptic feedback.
Background task nativo fica como próximo passo documentado no `mobile/README.md`.

## Issue 3

Classificador heurístico compartilhado:

- Python em `classifier/imu_classifier.py` (testável no CI)
- Dart em `mobile/lib/services/imu_service.dart` (execução na borda)

A troca para um modelo leve (TFLite) entra depois que houver telemetria real.
