import 'package:flutter_test/flutter_test.dart';
import 'package:primeiro_radiante/core/forecasting/forecast_validation.dart';

void main() {
  test('mede erro, viés e cobertura da faixa de previsão', () {
    final result = const ForecastValidator().evaluate(
      observations: const [
        ForecastObservation(period: 1, value: 10),
        ForecastObservation(period: 2, value: 20),
        ForecastObservation(period: 3, value: 30),
      ],
      forecasts: const [
        ForecastInterval(period: 1, p10: 8, p50: 11, p90: 14),
        ForecastInterval(period: 2, p10: 18, p50: 19, p90: 22),
        ForecastInterval(period: 3, p10: 20, p50: 24, p90: 26),
      ],
    );

    expect(result.meanAbsoluteError, closeTo(2.6667, 0.001));
    expect(result.rootMeanSquaredError, closeTo(3.559, 0.001));
    expect(result.meanBias, closeTo(-2, 0.001));
    expect(result.intervalCoverage, closeTo(2 / 3, 0.001));
    expect(result.reliabilityLabel, 'faixa parcialmente calibrada');
  });

  test('rejeita faixas invertidas', () {
    expect(
      () => const ForecastValidator().evaluate(
        observations: const [ForecastObservation(period: 1, value: 10)],
        forecasts: const [
          ForecastInterval(period: 1, p10: 12, p50: 10, p90: 14),
        ],
      ),
      throwsArgumentError,
    );
  });
}
