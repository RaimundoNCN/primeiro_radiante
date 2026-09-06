import 'dart:math' as math;

typedef ScenarioStep =
    Map<String, double> Function(
      Map<String, double> state,
      int step,
      math.Random random,
    );

class ScenarioSimulationResult {
  const ScenarioSimulationResult(this.states);

  final List<Map<String, double>> states;

  Map<String, double> get finalState => states.last;
}

class ScenarioSimulator {
  const ScenarioSimulator();

  ScenarioSimulationResult run({
    required Map<String, double> initialState,
    required int steps,
    required ScenarioStep update,
    int seed = 0,
  }) {
    if (steps < 0) {
      throw ArgumentError.value(steps, 'steps', 'must be non-negative');
    }

    final random = math.Random(seed);
    var state = Map<String, double>.unmodifiable(initialState);
    final states = <Map<String, double>>[state];

    for (var step = 1; step <= steps; step++) {
      final nextState = update(Map.unmodifiable(state), step, random);
      if (nextState.keys.any((key) => !nextState[key]!.isFinite)) {
        throw ArgumentError('Scenario update returned a non-finite value');
      }
      state = Map<String, double>.unmodifiable(nextState);
      states.add(state);
    }

    return ScenarioSimulationResult(List.unmodifiable(states));
  }
}
