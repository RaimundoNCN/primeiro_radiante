import 'package:flutter_test/flutter_test.dart';
import 'package:primeiro_radiante/core/analysis/influence_network.dart';
import 'package:primeiro_radiante/core/analysis/markov_chain.dart';
import 'package:primeiro_radiante/core/analysis/scenario_simulator.dart';
import 'package:primeiro_radiante/core/analysis/time_series.dart';
import 'package:primeiro_radiante/core/persistence/analysis_database.dart';
import 'package:primeiro_radiante/core/observatory/trend_observatory.dart';
import 'package:primeiro_radiante/core/forecasting/csv_forecast_parser.dart';

void main() {
  test('simula cenários preservando o estado inicial e a semente', () {
    final result = const ScenarioSimulator().run(
      initialState: {'population': 100},
      steps: 2,
      seed: 7,
      update: (state, step, random) => {
        'population': state['population']! + step * 10 + random.nextInt(1),
      },
    );

    expect(result.states.map((state) => state['population']), [100, 110, 130]);
  });

  test('calcula evolução e distribuição estacionária de Markov', () {
    final chain = MarkovChain([
      [0.8, 0.2],
      [0.4, 0.6],
    ]);

    expect(chain.distributionAfter([1, 0], 1)[0], closeTo(0.8, 1e-10));
    expect(chain.stationaryDistribution(), [
      closeTo(2 / 3, 1e-8),
      closeTo(1 / 3, 1e-8),
    ]);
    expect(() => chain.distributionAfter([0.8, 0.3], 1), throwsArgumentError);
  });

  test('calcula média móvel e tendência linear', () {
    final analysis = TimeSeriesAnalysis([
      const TimeSeriesPoint(1, 2),
      const TimeSeriesPoint(2, 4),
      const TimeSeriesPoint(3, 6),
    ]);

    expect(analysis.movingAverage(2), [3, 5]);
    expect(analysis.linearForecast(2).map((point) => point.value), [8, 10]);
  });

  test('mede influência recebida e propagada na rede', () {
    final network = InfluenceNetwork(
      nodes: ['A', 'B', 'C'],
      edges: const [InfluenceEdge('A', 'B', 0.5), InfluenceEdge('B', 'C', 0.8)],
    );

    expect(network.weightedInDegree()['C'], 0.8);
    expect(network.propagate(source: 'A', steps: 2)['C'], closeTo(0.4, 1e-10));
  });

  test('serializa e restaura uma execução persistida', () {
    final original = AnalysisRunRecord(
      id: 4,
      scenarioName: 'Cenário base',
      kind: 'scenario',
      input: const {'growth': '0.12'},
      result: 'Estado final: 176.23',
      values: const [100, 112, 125.44],
      createdAt: DateTime.utc(2026, 9, 5),
    );

    final restored = AnalysisRunRecord.fromMap(original.toMap());

    expect(restored.scenarioName, original.scenarioName);
    expect(restored.input['growth'], '0.12');
    expect(restored.values, original.values);
  });

  test('observa tendências, crises, instituições e contrafactuais', () {
    final result = const TrendObservatory().observe(
      groups: const [
        CollectiveGroup(
          name: 'A',
          population: 1000,
          stability: 0.7,
          resources: 60,
        ),
        CollectiveGroup(
          name: 'B',
          population: 500,
          stability: 0.6,
          resources: 50,
        ),
      ],
      institutions: const [
        InstitutionState(name: 'Ciência', influence: 0.9, decay: 0.05),
        InstitutionState(name: 'Comércio', influence: 0.6, decay: 0.1),
      ],
      events: const [HistoricalEvent(period: 5, name: 'Choque', impact: -20)],
      periods: 12,
      simulations: 20,
      seed: 42,
    );

    expect(result.history, hasLength(13));
    expect(result.monteCarlo, hasLength(20));
    expect(result.crises, isNotEmpty);
    expect(result.institutionInfluence, contains('Ciência'));
    expect(result.ideaReach, contains('A'));
    expect(result.counterfactualDelta, isNot(0));
    expect(result.explanation, contains('estabilidade'));
    expect(result.p10, lessThanOrEqualTo(result.p50));
    expect(result.p50, lessThanOrEqualTo(result.p90));
    expect(result.criticalPeriod, 5);
    expect(result.mostAffectedGroup, isNotNull);
    final comparison = const TrendObservatory().compare(result, result);
    expect(comparison.stabilityDelta, 0);
  });

  test('interpreta CSV de observações e previsões', () {
    final parser = const ForecastCsvParser();
    expect(parser.observations('period,value\n1,10\n2,20'), hasLength(2));
    expect(parser.forecasts('period,p10,p50,p90\n1,8,10,12'), hasLength(1));
  });
}
