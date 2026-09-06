import 'package:flutter_test/flutter_test.dart';
import 'package:primeiro_radiante/core/forecasting/forecast_calibration.dart';
import 'package:primeiro_radiante/core/forecasting/forecast_validation.dart';

void main() {
  test('corrige viés e recalibra a largura dos intervalos', () {
    final result = const ForecastCalibrator().calibrate(
      observations: const [
        ForecastObservation(period: 1, value: 10),
        ForecastObservation(period: 2, value: 20),
        ForecastObservation(period: 3, value: 30),
      ],
      forecasts: const [
        ForecastInterval(period: 1, p10: 7, p50: 12, p90: 14),
        ForecastInterval(period: 2, p10: 17, p50: 22, p90: 24),
        ForecastInterval(period: 3, p10: 27, p50: 32, p90: 34),
      ],
    );

    expect(result.biasCorrection, closeTo(-2, 1e-10));
    expect(result.after.meanBias.abs(), lessThan(result.before.meanBias.abs()));
    expect(result.forecasts, hasLength(3));
  });
}
