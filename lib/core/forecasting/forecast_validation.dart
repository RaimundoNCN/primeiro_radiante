import 'dart:math' as math;

class ForecastObservation {
  const ForecastObservation({required this.period, required this.value});

  final int period;
  final double value;
}

class ForecastInterval {
  const ForecastInterval({
    required this.period,
    required this.p10,
    required this.p50,
    required this.p90,
  });

  final int period;
  final double p10;
  final double p50;
  final double p90;
}

class ForecastValidationResult {
  const ForecastValidationResult({
    required this.meanAbsoluteError,
    required this.rootMeanSquaredError,
    required this.meanBias,
    required this.intervalCoverage,
    required this.evaluatedPeriods,
    required this.reliabilityLabel,
  });

  final double meanAbsoluteError;
  final double rootMeanSquaredError;
  final double meanBias;
  final double intervalCoverage;
  final int evaluatedPeriods;
  final String reliabilityLabel;
}

class ForecastValidator {
  const ForecastValidator();

  ForecastValidationResult evaluate({
    required List<ForecastObservation> observations,
    required List<ForecastInterval> forecasts,
  }) {
    if (observations.isEmpty || forecasts.isEmpty) {
      throw ArgumentError('Observations and forecasts must not be empty');
    }

    final actualByPeriod = {
      for (final observation in observations)
        observation.period: observation.value,
    };
    final matches = forecasts.where((forecast) {
      final actual = actualByPeriod[forecast.period];
      return actual != null &&
          actual.isFinite &&
          forecast.p10.isFinite &&
          forecast.p50.isFinite &&
          forecast.p90.isFinite &&
          forecast.p10 <= forecast.p50 &&
          forecast.p50 <= forecast.p90;
    }).toList();
    if (matches.isEmpty) {
      throw ArgumentError(
        'No forecast period can be compared with observations',
      );
    }

    var absoluteError = 0.0;
    var squaredError = 0.0;
    var bias = 0.0;
    var covered = 0;
    for (final forecast in matches) {
      final actual = actualByPeriod[forecast.period]!;
      final error = forecast.p50 - actual;
      absoluteError += error.abs();
      squaredError += error * error;
      bias += error;
      if (actual >= forecast.p10 && actual <= forecast.p90) covered++;
    }
    final coverage = covered / matches.length;
    return ForecastValidationResult(
      meanAbsoluteError: absoluteError / matches.length,
      rootMeanSquaredError: math.sqrt(squaredError / matches.length),
      meanBias: bias / matches.length,
      intervalCoverage: coverage,
      evaluatedPeriods: matches.length,
      reliabilityLabel: _label(coverage),
    );
  }

  String _label(double coverage) {
    if (coverage >= 0.8) return 'faixa com boa cobertura';
    if (coverage >= 0.6) return 'faixa parcialmente calibrada';
    return 'faixa subcalibrada';
  }
}
