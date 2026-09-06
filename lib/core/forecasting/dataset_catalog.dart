import 'forecast_validation.dart';

class ForecastDataset {
  const ForecastDataset({
    required this.id,
    required this.title,
    required this.version,
    required this.source,
    required this.observations,
  });

  final String id;
  final String title;
  final String version;
  final String source;
  final List<ForecastObservation> observations;
}

class ForecastDatasetCatalog {
  static const builtIn = [
    ForecastDataset(
      id: 'synthetic-growth-v1',
      title: 'Crescimento sintético',
      version: '1.0.0',
      source: 'Gerado localmente para testes, não representa dados reais.',
      observations: [
        ForecastObservation(period: 1, value: 10),
        ForecastObservation(period: 2, value: 12),
        ForecastObservation(period: 3, value: 15),
        ForecastObservation(period: 4, value: 18),
        ForecastObservation(period: 5, value: 22),
      ],
    ),
  ];
}
