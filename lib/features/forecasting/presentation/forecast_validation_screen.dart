import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/forecasting/csv_forecast_parser.dart';
import '../../../core/forecasting/forecast_calibration.dart';
import '../../../core/forecasting/dataset_catalog.dart';
import '../../../core/forecasting/forecast_validation.dart';
import '../../../core/theme/radiant_theme.dart';

class ForecastValidationScreen extends StatefulWidget {
  const ForecastValidationScreen({super.key});

  @override
  State<ForecastValidationScreen> createState() =>
      _ForecastValidationScreenState();
}

class _ForecastValidationScreenState extends State<ForecastValidationScreen> {
  final _observations = TextEditingController(
    text: 'period,value\n1,10\n2,20\n3,30\n4,40',
  );
  final _forecasts = TextEditingController(
    text: 'period,p10,p50,p90\n1,8,11,14\n2,18,19,22\n3,25,29,34\n4,35,41,47',
  );
  ForecastValidationResult? _result;
  ForecastCalibrationResult? _calibration;
  String? _error;

  @override
  void dispose() {
    _observations.dispose();
    _forecasts.dispose();
    super.dispose();
  }

  void _validate() {
    try {
      final parser = const ForecastCsvParser();
      final result = const ForecastValidator().evaluate(
        observations: parser.observations(_observations.text),
        forecasts: parser.forecasts(_forecasts.text),
      );
      setState(() {
        _result = result;
        _calibration = null;
        _error = null;
      });
    } on Object catch (error) {
      setState(() {
        _result = null;
        _error = 'Não foi possível validar: $error';
      });
    }
  }

  Future<void> _importCsv(TextEditingController target) async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final file = selection?.files.single;
    if (file?.bytes == null) return;
    target.text = utf8.decode(file!.bytes!);
    setState(() {
      _result = null;
      _calibration = null;
      _error = null;
    });
  }

  void _loadBuiltInDataset() {
    final dataset = ForecastDatasetCatalog.builtIn.first;
    _observations.text = [
      'period,value',
      for (final observation in dataset.observations)
        '${observation.period},${observation.value}',
    ].join('\n');
    setState(() {
      _result = null;
      _calibration = null;
      _error = null;
    });
  }

  void _calibrate() {
    try {
      final parser = const ForecastCsvParser();
      final result = const ForecastCalibrator().calibrate(
        observations: parser.observations(_observations.text),
        forecasts: parser.forecasts(_forecasts.text),
      );
      setState(() {
        _calibration = result;
        _result = result.after;
        _error = null;
      });
    } on Object catch (error) {
      setState(() => _error = 'Não foi possível calibrar: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Validação de previsões')),
      body: ListView(
        key: const Key('forecast-validation-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'BACKTESTING',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: RadiantColors.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confronte o modelo com observações',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Use dados históricos que não foram usados para ajustar o modelo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _input(
            _observations,
            'Observações CSV',
            'period,value',
            () => _importCsv(_observations),
          ),
          _input(
            _forecasts,
            'Previsões CSV',
            'period,p10,p50,p90',
            () => _importCsv(_forecasts),
          ),
          OutlinedButton.icon(
            key: const Key('load-dataset'),
            onPressed: _loadBuiltInDataset,
            icon: const Icon(Icons.dataset_outlined),
            label: const Text('Carregar dataset sintético v1.0.0'),
          ),
          FilledButton.icon(
            key: const Key('validate-forecast'),
            onPressed: _validate,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Calcular validação'),
          ),
          if (_result != null)
            OutlinedButton.icon(
              key: const Key('calibrate-forecast'),
              onPressed: _calibrate,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Calibrar automaticamente'),
            ),
          if (_error != null)
            _panel('Dados inválidos', _error!, Icons.warning_amber_rounded),
          if (result != null) ...[
            const SizedBox(height: 16),
            _panel(
              'Confiabilidade',
              '${result.reliabilityLabel}\nPeríodos avaliados: ${result.evaluatedPeriods}',
              Icons.verified_outlined,
            ),
            _metrics(result),
            if (_calibration != null)
              _panel(
                'Calibração aplicada',
                'Correção de viés: ${_calibration!.biasCorrection.toStringAsFixed(3)}\nEscala da faixa: ${_calibration!.intervalScale.toStringAsFixed(3)}\nAntes: ${_calibration!.before.reliabilityLabel}\nDepois: ${_calibration!.after.reliabilityLabel}',
                Icons.tune_rounded,
              ),
            _panel(
              'Interpretação',
              'MAE mede o erro médio absoluto. RMSE penaliza erros grandes. Viés positivo indica superestimação; negativo indica subestimação. Cobertura mostra quantas observações caíram entre P10 e P90.',
              Icons.help_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    String hint,
    VoidCallback onImport,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      minLines: 4,
      maxLines: 8,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        suffixIcon: IconButton(
          tooltip: 'Importar CSV',
          onPressed: onImport,
          icon: const Icon(Icons.file_upload_outlined),
        ),
      ),
    ),
  );

  Widget _metrics(ForecastValidationResult result) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _metric('MAE', result.meanAbsoluteError),
      _metric('RMSE', result.rootMeanSquaredError),
      _metric('Viés', result.meanBias),
      _metric('Cobertura', result.intervalCoverage),
    ],
  );

  Widget _metric(String label, double value) => SizedBox(
    width: 145,
    child: Material(
      color: RadiantColors.surfaceBright,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(
              value.toStringAsFixed(3),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _panel(String title, String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Material(
      color: RadiantColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: RadiantColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(text),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
