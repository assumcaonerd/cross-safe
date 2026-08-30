# CrossSafe Mobile

Cliente de borda (Flutter) previsto nas issues #2 e #3.

Este diretório traz o esqueleto do app: papéis (motorista, e-bike, pedestre),
geofence via GPS, classificação IMU leve e alerta háptico.

## Como materializar o projeto nativo

O repositório não versiona as pastas `android/` e `ios/` geradas pelo SDK.
Na máquina com Flutter instalado:

```bash
cd mobile
flutter create . --project-name cross_safe --org br.gov.crosssafe
flutter pub get
```

Depois disso, configure no AndroidManifest e no Info.plist:

- localização em primeiro e segundo plano
- sensores de movimento
- vibração

A tarefa de background verdadeira (issue #2) ainda precisa do plugin
`flutter_foreground_task` ou workmanager. O ciclo `watch()` do
`GeofenceService` é o ponto de encaixe.

API padrão no emulador Android: `http://10.0.2.2:8000`.
