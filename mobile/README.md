# CrossSafe Mobile

Cliente Flutter de borda para motorista, e-bike/patinete e pedestre.

## Estado da v0.2

- geofence por GPS com consulta ao FastAPI;
- IMU real a 50 Hz com janela de 2 segundos;
- alertas 1.2, 1.3, 1.4 e modo LEV;
- telemetria gravada primeiro em SQLite e sincronizada depois;
- dead-letter local para payloads rejeitados permanentemente;
- overlay Android nativo para o fluxo de pedestre.

## Materializar o scaffold nativo

O repositorio versiona os arquivos Android customizados do CrossSafe, mas nao
todo o scaffold gerado pelo Flutter. Em uma maquina com Flutter instalado:

```bash
cd mobile
flutter create . --platforms=android,ios --project-name cross_safe --org com.crosssafe
flutter pub get
```

O namespace Android esperado e `com.crosssafe.cross_safe`. Nao gere o projeto
com outro `--org`, pois isso quebra a resolucao de `MainActivity` e do servico
de overlay.

No iOS, adicione as descricoes de uso de localizacao e movimento exigidas pelo
sistema antes de executar em dispositivo real.

## URL da API

No emulador Android, o padrao e `http://10.0.2.2:8000`. Em desktop/iOS simulator,
o padrao e `http://127.0.0.1:8000`.

Para aparelho fisico ou ambiente remoto, passe a URL explicitamente:

```bash
flutter run --dart-define=CROSSSAFE_API_BASE_URL=http://192.168.1.10:8000
```

Em producao use HTTPS.

## Background

O monitoramento atual funciona enquanto o ciclo do aplicativo esta ativo. A
execucao de geofence/IMU de longa duracao em segundo plano continua sendo uma
etapa separada, pois Android e iOS possuem politicas especificas de bateria,
localizacao e foreground service. Nao trate o fluxo atual como background
continuo ate essa etapa ser implementada e validada em dispositivo real.
