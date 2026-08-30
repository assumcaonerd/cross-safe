# Interface 1.3: Estado de Interrupção Cognitiva

Tela de alerta do motorista. Objetivo: quebrar o uso do celular e forçar
atenção à faixa quando o veículo entra na janela cinemática de risco.

## Regras

- Tela cheia, sem AppBar, modo imersivo
- Palavra única de ação: FREIE
- Distância restante da geofence
- Velocidade instantânea e vetor de aproximação
- Barra inferior: HUD injetado + alvo de áudio mono
- Pulso visual ~420 ms e ciclo háptico/sonoro ~900 ms
- Não deve ser descartável por gesto acidental (botão explícito de reconhecimento)

## Implementação

`mobile/lib/screens/driver_interrupt_screen.dart`

Disparo automático no papel Motorista quando a faixa entra na janela de
frenagem. Há um botão de prévia na home para inspecionar o estado sem GPS.
