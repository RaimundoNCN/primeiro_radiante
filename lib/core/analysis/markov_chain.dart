class MarkovChain {
  MarkovChain(List<List<double>> transitions)
    : transitions = _validateAndCopy(transitions);

  final List<List<double>> transitions;

  int get stateCount => transitions.length;

  List<double> nextDistribution(List<double> distribution) {
    _validateDistribution(distribution);
    final result = List<double>.filled(stateCount, 0);
    for (var source = 0; source < stateCount; source++) {
      for (var target = 0; target < stateCount; target++) {
        result[target] += distribution[source] * transitions[source][target];
      }
    }
    return result;
  }

  List<double> distributionAfter(List<double> initial, int steps) {
    if (steps < 0) {
      throw ArgumentError.value(steps, 'steps', 'must be non-negative');
    }
    _validateDistribution(initial);
    var distribution = List<double>.from(initial);
    for (var step = 0; step < steps; step++) {
      distribution = nextDistribution(distribution);
    }
    return distribution;
  }

  List<double> stationaryDistribution({
    int iterations = 1_000,
    double tolerance = 1e-10,
  }) {
    var distribution = List<double>.filled(stateCount, 1 / stateCount);
    for (var iteration = 0; iteration < iterations; iteration++) {
      final next = nextDistribution(distribution);
      final difference = List.generate(
        stateCount,
        (index) => (next[index] - distribution[index]).abs(),
      ).reduce((left, right) => left > right ? left : right);
      distribution = next;
      if (difference <= tolerance) {
        break;
      }
    }
    return distribution;
  }

  static List<List<double>> _validateAndCopy(List<List<double>> source) {
    if (source.isEmpty || source.any((row) => row.length != source.length)) {
      throw ArgumentError('Transition matrix must be non-empty and square');
    }
    return List<List<double>>.unmodifiable(
      source.map<List<double>>((row) {
        final sum = row.fold<double>(0, (total, value) => total + value);
        if (row.any((value) => !value.isFinite || value < 0) ||
            (sum - 1).abs() > 1e-10) {
          throw ArgumentError(
            'Each transition row must be a probability distribution',
          );
        }
        return List.unmodifiable(row);
      }),
    );
  }

  void _validateDistribution(List<double> distribution) {
    if (distribution.length != stateCount) {
      throw ArgumentError('Distribution size must match state count');
    }
    final sum = distribution.fold<double>(0, (total, value) => total + value);
    if (distribution.any((value) => !value.isFinite || value < 0) ||
        (sum - 1).abs() > 1e-10) {
      throw ArgumentError(
        'Distribution must contain non-negative probabilities summing to 1',
      );
    }
  }
}
