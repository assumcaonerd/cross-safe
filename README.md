# CrossSafe

Plataforma open source de cidade inteligente para reduzir distracao digital e
proteger vidas em faixas de pedestres. Conecta motoristas, pedestres e
condutores de e-bike com classificacao na borda, geofence e telemetria para
priorizacao da infraestrutura urbana.

Licenca: Apache 2.0.

## Estado atual: v0.2 de desenvolvimento

O repositorio possui um circuito funcional de desenvolvimento:

- `backend/`: FastAPI + PostgreSQL/PostGIS;
- `backend/alembic/`: migrations e seeds versionados;
- `classifier/`: classificador IMU heuristico em Python;
- `mobile/`: Flutter com GPS, IMU a 50 Hz, haptic e interfaces de alerta;
- telemetria mobile persistida primeiro em SQLite e sincronizada com a API;
- ranking municipal para frenagens bruscas e interrupcoes de pedestre;
- CI com PostGIS real, testes de integracao, analise Flutter e build Android.

A v0.2 ainda e uma base de piloto. Monitoramento continuo em background,
politica final de autenticacao da API, calibracao com telemetria de campo e
validacao em dispositivos reais continuam no roadmap.

## Subir backend localmente

```bash
docker compose up --build
```

O container da API espera o PostGIS ficar pronto e executa automaticamente:

```bash
alembic upgrade head
```

Depois:

- health: `http://localhost:8000/health`
- OpenAPI: `http://localhost:8000/docs`

O `/health` retorna HTTP 503 quando o banco/PostGIS nao esta disponivel.

## Testes Python

Os testes unitarios continuam podendo rodar sem banco:

```bash
pip install -r backend/requirements.txt
pytest -q
```

Os testes de integracao com PostGIS sao executados pelo GitHub Actions com
`CROSSSAFE_INTEGRATION=1`.

## Mobile

Leia `mobile/README.md` para gerar o scaffold nativo e configurar a URL da API.
Em aparelho fisico, use `CROSSSAFE_API_BASE_URL` via `--dart-define`.

## Arquitetura resumida

1. GPS localiza faixas dentro de um raio dinamico.
2. IMU classifica o padrao de movimento e detecta eventos bruscos.
3. O papel selecionado define o alerta para motorista, LEV ou pedestre.
4. O evento e salvo localmente antes de qualquer tentativa de rede.
5. A API persiste a telemetria no PostGIS.
6. Eventos relevantes alimentam o ranking municipal de prioridade.

Detalhes em `docs/architecture.md`.

## Contribuicao

Siga `CONTRIBUTING.md`. Desenvolvimento entra por `develop`; mudancas para
`main` devem passar por pull request e CI.
