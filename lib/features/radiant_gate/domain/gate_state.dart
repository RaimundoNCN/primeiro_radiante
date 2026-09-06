enum RadiantGatePhase { awaitingCircle, awaitingTaps, unlocking }

extension RadiantGatePhaseText on RadiantGatePhase {
  String get instruction => switch (this) {
    RadiantGatePhase.awaitingCircle =>
      'Desenhe um círculo para despertar o Radiante',
    RadiantGatePhase.awaitingTaps => 'Círculo reconhecido. Dê três toques',
    RadiantGatePhase.unlocking => 'O Núcleo está respondendo',
  };
}
