import 'forecast_validation.dart';

class ForecastCalibrationResult {
  const ForecastCalibrationResult({
    required this.biasCorrection,
    required this.intervalScale,
    required this.before,
    required this.after,
    required this.forecasts,
  });

  final double biasCorrection;
  final double intervalScale;
  final ForecastValidationResult before;
  final ForecastValidationResult after;
  final List<ForecastInterval> forecasts;
}

class ForecastCalibrator {
  const ForecastCalibrator();

  ForecastCalibrationResult calibrate({
    required List<ForecastObservation> observations,
    required List<ForecastInterval> forecasts,
  }) {
    final validator = const ForecastValidator();
    final before = validator.evaluate(
      observations: observations,
      forecasts: forecasts,
    );
    final actual = {
      for (final observation in observations)
        observation.period: observation.value,
    };
    final correction = -before.meanBias;
    final residuals = forecasts
        .where((forecast) => actual.containsKey(forecast.period))
        .map(
          (forecast) =>
              (forecast.p50 + correction - actual[forecast.period]!).abs(),
        )
        .toList();
    final typicalError = residuals.isEmpty
        ? 0.0
        : residuals.reduce((a, b) => a > b ? a : b);
    final typicalWidth = forecasts.isEmpty
        ? 1.0
        : forecasts
                  .map((forecast) => forecast.p90 - forecast.p10)
                  .reduce((a, b) => a + b) /
              forecasts.length;
    final scale = typicalWidth <= 0
        ? 1.0
        : (typicalError * 2 / typicalWidth).clamp(1.0, 4.0);
    final calibrated = forecasts.map((forecast) {
      final midpoint = forecast.p50 + correction;
      final halfWidth = (forecast.p90 - forecast.p10) / 2 * scale;
      return ForecastInterval(
        period: forecast.period,
        p10: midpoint - halfWidth,
        p50: midpoint,
        p90: midpoint + halfWidth,
      );
    }).toList();
    final after = validator.evaluate(
      observations: observations,
      forecasts: calibrated,
    );
    return ForecastCalibrationResult(
      biasCorrection: correction,
      intervalScale: scale,
      before: before,
      after: after,
      forecasts: calibrated,
    );
  }
}
