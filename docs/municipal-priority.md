# Score municipal

O ranking municipal usa os eventos persistidos em `incident_telemetry`.

```text
R_c = (1.5 * hard_brake + 1.0 * occlusion) * Z
Z = 2 quando a faixa esta a ate 80 m de uma zona school ou hospital.
LEVEL_1_CRITICAL quando R_c >= 5.
```

Endpoints:

```text
GET /v1/municipal/priority-tickets?city=Vitoria
GET /v1/municipal/priority-tickets.csv?city=Vitoria
```

O schema e os seeds das zonas municipais sao gerenciados por Alembic em
`backend/alembic/versions/`. Execute `alembic upgrade head` antes de iniciar a
API fora do Docker. No `docker-compose`, a migracao ocorre automaticamente no
startup do container da API.
