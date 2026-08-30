# CrossSafe

Plataforma open source de cidade inteligente para reduzir distração digital e
proteger vidas em faixas de pedestres. Conecta motoristas, pedestres e
condutores de e-bike com telemetria na borda, geofence e auditoria
colaborativa da infraestrutura.

Licença: Apache 2.0.

## Estado atual

O repositório deixou de ser só manifesto. A branch de trabalho agora tem um
monorepo mínimo alinhado às issues #1, #2 e #3:

- `backend/` FastAPI + PostGIS (faixas, zonas, telemetria, busca por raio)
- `classifier/` motor IMU heurístico, testado no CI
- `mobile/` esqueleto Flutter (geofence, IMU, haptic)
- `docker-compose.yml` sobe Postgres/PostGIS e a API

## Subir localmente

```bash
docker compose up --build
```

API em `http://localhost:8000/health` e docs em `http://localhost:8000/docs`.

Testes sem banco:

```bash
pip install -r backend/requirements.txt
pytest -q
```

App mobile: leia `mobile/README.md`.

## Arquitetura resumida

1. Motorista e motociclista: janela de alerta cresce com a velocidade.
2. E-bike e patinete: o IMU tenta separar LEV de carro e de pedestre.
3. Pedestre: se a tela está ativa perto de uma faixa, o app interrompe.
4. Prefeitura: telemetria anônima e relatos viram prioridade de manutenção.

Detalhe em `docs/architecture.md`.

## Contribuição

Siga `CONTRIBUTING.md`. Desenvolvimento entra por `develop`. Branches de
feature no formato `feature/issue-[ID]-short-desc`.
