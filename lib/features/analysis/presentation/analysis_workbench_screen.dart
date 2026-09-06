import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/analysis/influence_network.dart';
import '../../../core/analysis/markov_chain.dart';
import '../../../core/analysis/scenario_simulator.dart';
import '../../../core/analysis/time_series.dart';
import '../../../core/math/expression_engine.dart';
import '../../../core/persistence/analysis_database.dart';
import '../../../core/theme/radiant_theme.dart';
import '../../documentation/presentation/documentation_screen.dart';

enum AnalysisKind { expression, scenario, markov, timeSeries, network }

extension AnalysisKindDetails on AnalysisKind {
  String get title => switch (this) {
    AnalysisKind.expression => 'Expressão e variáveis',
    AnalysisKind.scenario => 'Simulação de cenário',
    AnalysisKind.markov => 'Cadeia de Markov',
    AnalysisKind.timeSeries => 'Série temporal',
    AnalysisKind.network => 'Rede e influência',
  };

  String get description => switch (this) {
    AnalysisKind.expression => 'Calcule uma fórmula verificável',
    AnalysisKind.scenario => 'Evolua uma população por etapas',
    AnalysisKind.markov => 'Observe transições entre estados',
    AnalysisKind.timeSeries => 'Encontre tendência e média móvel',
    AnalysisKind.network => 'Propague influência entre nós',
  };

  IconData get icon => switch (this) {
    AnalysisKind.expression => Icons.functions_rounded,
    AnalysisKind.scenario => Icons.timeline_rounded,
    AnalysisKind.markov => Icons.alt_route_rounded,
    AnalysisKind.timeSeries => Icons.show_chart_rounded,
    AnalysisKind.network => Icons.hub_outlined,
  };
}

class AnalysisWorkbenchScreen extends StatefulWidget {
  const AnalysisWorkbenchScreen({super.key});

  @override
  State<AnalysisWorkbenchScreen> createState() =>
      _AnalysisWorkbenchScreenState();
}

class _AnalysisWorkbenchScreenState extends State<AnalysisWorkbenchScreen> {
  AnalysisKind _kind = AnalysisKind.scenario;
  String? _result;
  String? _error;
  List<double> _resultValues = const [];
  final List<_AnalysisSnapshot> _history = [];
  final _scenarioName = TextEditingController(text: 'Experiência inicial');
  final _expression = TextEditingController(
    text: 'population * (1 + growth) ^ periods',
  );
  final _expressionVariables = TextEditingController(
    text: 'population=100,growth=0.12,periods=5',
  );

  final _scenarioInitial = TextEditingController(text: '100');
  final _scenarioGrowth = TextEditingController(text: '0.12');
  final _scenarioSteps = TextEditingController(text: '5');
  final _scenarioSeed = TextEditingController(text: '7');

  final _markovMatrix = TextEditingController(text: '0.8,0.2;0.4,0.6');
  final _markovInitial = TextEditingController(text: '1,0');
  final _markovSteps = TextEditingController(text: '10');

  final _seriesValues = TextEditingController(text: '12, 15, 14, 18, 21, 24');
  final _seriesWindow = TextEditingController(text: '3');
  final _seriesForecast = TextEditingController(text: '3');

  final _networkEdges = TextEditingController(
    text: 'A>B:0.8, B>C:0.6, A>C:0.2',
  );
  final _networkSource = TextEditingController(text: 'A');
  final _networkSteps = TextEditingController(text: '2');
  final _networkDecay = TextEditingController(text: '0.9');

  @override
  void dispose() {
    for (final controller in [
      _scenarioInitial,
      _scenarioGrowth,
      _scenarioSteps,
      _scenarioSeed,
      _markovMatrix,
      _markovInitial,
      _markovSteps,
      _seriesValues,
      _seriesWindow,
      _seriesForecast,
      _networkEdges,
      _networkSource,
      _networkSteps,
      _networkDecay,
      _scenarioName,
      _expression,
      _expressionVariables,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCurrent() async {
    if (_result == null) {
      setState(() => _error = 'Execute uma análise antes de salvar.');
      return;
    }
    try {
      await AnalysisDatabase.instance.saveRun(
        scenarioName: _scenarioName.text.trim().isEmpty
            ? 'Sem nome'
            : _scenarioName.text.trim(),
        kind: _kind.name,
        input: _currentInput(),
        result: _result!,
        values: _resultValues,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cenário salvo localmente.')),
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = 'Não foi possível salvar: $error');
    }
  }

  Future<void> _export(String format) async {
    try {
      final text = format == 'json'
          ? await AnalysisDatabase.instance.exportJson()
          : await AnalysisDatabase.instance.exportText();
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exportação $format copiada.')));
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = 'Não foi possível exportar: $error');
    }
  }

  Map<String, Object?> _currentInput() => switch (_kind) {
    AnalysisKind.expression => {
      'expression': _expression.text,
      'variables': _expressionVariables.text,
    },
    AnalysisKind.scenario => {
      'initial': _scenarioInitial.text,
      'growth': _scenarioGrowth.text,
      'steps': _scenarioSteps.text,
      'seed': _scenarioSeed.text,
    },
    AnalysisKind.markov => {
      'matrix': _markovMatrix.text,
      'initial': _markovInitial.text,
      'steps': _markovSteps.text,
    },
    AnalysisKind.timeSeries => {
      'values': _seriesValues.text,
      'window': _seriesWindow.text,
      'forecast': _seriesForecast.text,
    },
    AnalysisKind.network => {
      'edges': _networkEdges.text,
      'source': _networkSource.text,
      'steps': _networkSteps.text,
      'decay': _networkDecay.text,
    },
  };

  void _runAnalysis() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _error = null;
      _result = null;
      _resultValues = const [];
      try {
        final output = switch (_kind) {
          AnalysisKind.expression => _runExpression(),
          AnalysisKind.scenario => _runScenario(),
          AnalysisKind.markov => _runMarkov(),
          AnalysisKind.timeSeries => _runTimeSeries(),
          AnalysisKind.network => _runNetwork(),
        };
        _result = output.text;
        _resultValues = output.values;
        _history.add(
          _AnalysisSnapshot(
            kind: _kind,
            text: output.text,
            values: output.values,
          ),
        );
      } on Object catch (error) {
        _error = 'Não foi possível executar: ${_friendlyError(error)}';
      }
    });
  }

  _AnalysisOutput _runExpression() {
    final variables = <String, double>{};
    for (final item in _expressionVariables.text.split(',')) {
      final parts = item.split('=');
      if (parts.length != 2) throw const FormatException('use nome=valor');
      variables[parts[0].trim()] = double.parse(parts[1].trim());
    }
    final value = const ExpressionEngine().evaluate(
      _expression.text,
      variables,
    );
    if (!value.isFinite) throw const FormatException('resultado não finito');
    return _AnalysisOutput(
      text: 'Expressão: ${_expression.text}\nResultado: ${_format(value)}',
      values: [value],
    );
  }

  _AnalysisOutput _runScenario() {
    final initial = _number(_scenarioInitial);
    final growth = _number(_scenarioGrowth);
    final steps = _integer(_scenarioSteps);
    final seed = _integer(_scenarioSeed);
    final simulation = const ScenarioSimulator().run(
      initialState: {'population': initial},
      steps: steps,
      seed: seed,
      update: (state, _, random) => {
        'population': state['population']! * (1 + growth) + random.nextInt(1),
      },
    );
    final values = simulation.states.map((state) => state['population']!);
    return _AnalysisOutput(
      text:
          'Trajetória: ${_formatList(values)}\nEstado final: ${_format(values.last)}',
      values: values.toList(),
    );
  }

  _AnalysisOutput _runMarkov() {
    final rows = _markovMatrix.text
        .split(';')
        .map((row) => _numbers(row))
        .toList();
    final chain = MarkovChain(rows);
    final distribution = chain.distributionAfter(
      _numbers(_markovInitial.text),
      _integer(_markovSteps),
    );
    final stationary = chain.stationaryDistribution();
    return _AnalysisOutput(
      text:
          'Após ${_markovSteps.text.trim()} etapas: ${_formatList(distribution)}\n'
          'Estacionária: ${_formatList(stationary)}',
      values: distribution,
    );
  }

  _AnalysisOutput _runTimeSeries() {
    final values = _numbers(_seriesValues.text);
    final points = [
      for (var index = 0; index < values.length; index++)
        TimeSeriesPoint(index.toDouble(), values[index]),
    ];
    final analysis = TimeSeriesAnalysis(points);
    final averages = analysis.movingAverage(_integer(_seriesWindow));
    final forecast = analysis.linearForecast(_integer(_seriesForecast));
    final forecastValues = forecast.map((point) => point.value).toList();
    return _AnalysisOutput(
      text:
          'Média móvel: ${_formatList(averages)}\n'
          'Previsão: ${_formatList(forecastValues)}',
      values: [...values, ...forecastValues],
    );
  }

  _AnalysisOutput _runNetwork() {
    final parsedEdges = _networkEdges.text.split(',').map((part) {
      final pieces = part.trim().split(':');
      final nodes = pieces.first.split('>');
      if (pieces.length != 2 || nodes.length != 2) {
        throw const FormatException('use A>B:peso');
      }
      return InfluenceEdge(
        nodes[0].trim(),
        nodes[1].trim(),
        double.parse(pieces[1]),
      );
    }).toList();
    final nodes = parsedEdges.expand((edge) => [edge.source, edge.target]);
    final network = InfluenceNetwork(nodes: nodes, edges: parsedEdges);
    final influence = network.propagate(
      source: _networkSource.text.trim(),
      steps: _integer(_networkSteps),
      decay: _number(_networkDecay),
    );
    final ordered = influence.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return _AnalysisOutput(
      text:
          'Influência após ${_networkSteps.text.trim()} etapas:\n'
          '${ordered.map((entry) => '${entry.key}: ${_format(entry.value)}').join('  •  ')}',
      values: ordered.map((entry) => entry.value).toList(),
    );
  }

  double _number(TextEditingController controller) =>
      double.parse(controller.text.trim());

  int _integer(TextEditingController controller) =>
      int.parse(controller.text.trim());

  List<double> _numbers(String source) =>
      source.split(',').map((value) => double.parse(value.trim())).toList();

  String _format(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  String _formatList(Iterable<double> values) =>
      '[${values.map(_format).join(', ')}]';

  String _friendlyError(Object error) => error is FormatException
      ? 'verifique o formato dos campos.'
      : error.toString().replaceFirst('Invalid argument(s): ', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bancada de análise'),
        actions: [
          IconButton(
            tooltip: 'Documentação',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DocumentationScreen(),
              ),
            ),
            icon: const Icon(Icons.menu_book_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Exportar histórico',
            icon: const Icon(Icons.ios_share_rounded),
            onSelected: _export,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'json', child: Text('Copiar JSON')),
              PopupMenuItem(value: 'texto', child: Text('Copiar texto')),
            ],
          ),
          IconButton(
            tooltip: 'Limpar resultado',
            onPressed: () => setState(() {
              _result = null;
              _error = null;
            }),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('analysis-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Câmara de análise',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: RadiantColors.gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Teste uma hipótese',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Altere os valores, execute e compare o comportamento do sistema.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<AnalysisKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: 'Tipo de análise',
                prefixIcon: Icon(Icons.auto_graph_rounded),
              ),
              items: [
                for (final kind in AnalysisKind.values)
                  DropdownMenuItem(value: kind, child: Text(kind.title)),
              ],
              onChanged: (value) => setState(() {
                _kind = value!;
                _result = null;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('scenario-name'),
              controller: _scenarioName,
              decoration: const InputDecoration(
                labelText: 'Nome do cenário',
                prefixIcon: Icon(Icons.bookmark_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            _AnalysisCard(kind: _kind, child: _fieldsForKind()),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('run-analysis'),
              onPressed: _runAnalysis,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Executar análise'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('save-analysis'),
              onPressed: _saveCurrent,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar cenário localmente'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ResultPanel(
                icon: Icons.warning_amber_rounded,
                title: 'Entrada precisa de atenção',
                text: _error!,
                isError: true,
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultPanel(
                icon: Icons.insights_rounded,
                title: 'Leitura do Radiante',
                text: _result!,
                values: _resultValues,
              ),
            ],
            if (_history.length > 1) ...[
              const SizedBox(height: 16),
              _ComparisonPanel(history: _history, format: _format),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fieldsForKind() => switch (_kind) {
    AnalysisKind.expression => _fieldGroup([
      _field(
        _expression,
        'Expressão',
        'ex.: population * (1 + growth) ^ periods',
      ),
      _field(
        _expressionVariables,
        'Variáveis (nome=valor)',
        'ex.: population=100,growth=0.12,periods=5',
      ),
    ]),
    AnalysisKind.scenario => _fieldGroup([
      _field(_scenarioInitial, 'Estado inicial', 'ex.: 100'),
      _field(_scenarioGrowth, 'Crescimento por etapa', 'ex.: 0.12'),
      _field(_scenarioSteps, 'Etapas', 'ex.: 5'),
      _field(_scenarioSeed, 'Semente', 'ex.: 7'),
    ]),
    AnalysisKind.markov => _fieldGroup([
      _field(
        _markovMatrix,
        'Matriz (linhas separadas por ;)',
        'ex.: 0.8,0.2;0.4,0.6',
      ),
      _field(_markovInitial, 'Distribuição inicial', 'ex.: 1,0'),
      _field(_markovSteps, 'Etapas', 'ex.: 10'),
    ]),
    AnalysisKind.timeSeries => _fieldGroup([
      _field(
        _seriesValues,
        'Valores separados por vírgula',
        'ex.: 12, 15, 14, 18',
      ),
      _field(_seriesWindow, 'Janela da média móvel', 'ex.: 3'),
      _field(_seriesForecast, 'Períodos de previsão', 'ex.: 3'),
    ]),
    AnalysisKind.network => _networkFieldGroup(),
  };

  Widget _networkFieldGroup() => Column(
    children: [
      _field(_networkEdges, 'Arestas (A>B:peso)', 'ex.: A>B:0.8, B>C:0.6'),
      const SizedBox(height: 12),
      _field(_networkSource, 'Nó de origem', 'ex.: A'),
      const SizedBox(height: 12),
      _field(_networkSteps, 'Etapas', 'ex.: 2'),
      const SizedBox(height: 12),
      _field(_networkDecay, 'Decaimento', 'ex.: 0.9'),
      const SizedBox(height: 14),
      _NetworkEditor(
        edges: _previewEdges(),
        source: _networkSource.text.trim(),
      ),
    ],
  );

  List<InfluenceEdge> _previewEdges() {
    try {
      return _networkEdges.text.split(',').map((part) {
        final pieces = part.trim().split(':');
        final nodes = pieces.first.split('>');
        return InfluenceEdge(
          nodes[0].trim(),
          nodes[1].trim(),
          double.parse(pieces[1]),
        );
      }).toList();
    } on Object {
      return const [];
    }
  }

  Widget _fieldGroup(List<Widget> fields) => Column(
    children: [
      for (final field in fields) ...[field, const SizedBox(height: 12)],
    ],
  );

  Widget _field(TextEditingController controller, String label, String hint) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
      );
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.kind, required this.child});

  final AnalysisKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RadiantColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(kind.icon, color: RadiantColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    kind.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.icon,
    required this.title,
    required this.text,
    this.values = const [],
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final List<double> values;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isError ? const Color(0xFF291B12) : RadiantColors.surfaceBright,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isError ? Colors.orangeAccent : RadiantColors.luminousGold,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SelectableText(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (!isError && values.length > 1) ...[
                    const SizedBox(height: 16),
                    SizedBox(height: 110, child: _ValueChart(values: values)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisOutput {
  const _AnalysisOutput({required this.text, required this.values});

  final String text;
  final List<double> values;
}

class _AnalysisSnapshot {
  const _AnalysisSnapshot({
    required this.kind,
    required this.text,
    required this.values,
  });

  final AnalysisKind kind;
  final String text;
  final List<double> values;
}

class _ComparisonPanel extends StatelessWidget {
  const _ComparisonPanel({required this.history, required this.format});

  final List<_AnalysisSnapshot> history;
  final String Function(double value) format;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RadiantColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparação da sessão',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${history.length} execuções mantidas nesta sessão',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (history.length >= 2) ...[
              Text(
                'Últimas duas leituras',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final snapshot in history.skip(history.length - 2))
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ComparisonTile(
                          snapshot: snapshot,
                          format: format,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            for (var index = 0; index < history.length; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 15,
                  backgroundColor: RadiantColors.surfaceBright,
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                title: Text(history[index].kind.title),
                subtitle: Text(
                  history[index].values.isEmpty
                      ? 'Sem valores numéricos'
                      : 'Primeiro: ${format(history[index].values.first)}  •  Último: ${format(history[index].values.last)}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ValueChart extends StatefulWidget {
  const _ValueChart({required this.values});

  final List<double> values;

  @override
  State<_ValueChart> createState() => _ValueChartState();
}

class _ValueChartState extends State<_ValueChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final selected = _selectedIndex == null || _selectedIndex! >= values.length
        ? null
        : values[_selectedIndex!];
    return GestureDetector(
      key: const Key('value-chart'),
      onTapUp: (details) {
        if (values.length < 2) return;
        final index =
            (details.localPosition.dx / context.size!.width * values.length)
                .floor()
                .clamp(0, values.length - 1);
        setState(() => _selectedIndex = index);
      },
      child: Stack(
        children: [
          CustomPaint(
            painter: _ValueChartPainter(
              values: values,
              selectedIndex: _selectedIndex,
              color: RadiantColors.luminousGold,
              gridColor: RadiantColors.muted.withValues(alpha: 0.18),
            ),
            child: const SizedBox.expand(),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _ChartLabel(values.reduce((a, b) => a > b ? a : b)),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: _ChartLabel(values.reduce((a, b) => a < b ? a : b)),
          ),
          if (selected != null)
            Positioned(right: 0, top: 0, child: _ChartLabel(selected)),
        ],
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  const _ChartLabel(this.value);

  final double value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: RadiantColors.voidBlack.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        value.toStringAsFixed(2),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ),
  );
}

class _ValueChartPainter extends CustomPainter {
  const _ValueChartPainter({
    required this.values,
    required this.selectedIndex,
    required this.color,
    required this.gridColor,
  });

  final List<double> values;
  final int? selectedIndex;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final finiteValues = values.where((value) => value.isFinite).toList();
    if (finiteValues.length < 2) return;
    final minimum = finiteValues.reduce((a, b) => a < b ? a : b);
    final maximum = finiteValues.reduce((a, b) => a > b ? a : b);
    final range = maximum - minimum == 0 ? 1 : maximum - minimum;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var line = 1; line < 4; line++) {
      final y = size.height * line / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = size.height - ((values[index] - minimum) / range * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    if (selectedIndex != null && selectedIndex! < values.length) {
      final index = selectedIndex!;
      final x = size.width * index / (values.length - 1);
      final y = size.height - ((values[index] - minimum) / range * size.height);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ValueChartPainter oldDelegate) =>
      values != oldDelegate.values ||
      selectedIndex != oldDelegate.selectedIndex;
}

class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({required this.snapshot, required this.format});

  final _AnalysisSnapshot snapshot;
  final String Function(double value) format;

  @override
  Widget build(BuildContext context) {
    final value = snapshot.values.isEmpty ? null : snapshot.values.last;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: RadiantColors.surfaceBright,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snapshot.kind.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value == null ? '-' : format(value),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('último valor', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _NetworkEditor extends StatefulWidget {
  const _NetworkEditor({required this.edges, required this.source});

  final List<InfluenceEdge> edges;
  final String source;

  @override
  State<_NetworkEditor> createState() => _NetworkEditorState();
}

class _NetworkEditorState extends State<_NetworkEditor> {
  final Map<String, Offset> _positions = {};
  String? _draggedNode;

  @override
  Widget build(BuildContext context) {
    final nodes = widget.edges
        .expand((edge) => [edge.source, edge.target])
        .toSet()
        .toList();
    for (var index = 0; index < nodes.length; index++) {
      _positions.putIfAbsent(
        nodes[index],
        () => Offset(55 + (index % 3) * 100, 55 + (index ~/ 3) * 65),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mapa interativo', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SizedBox(
          key: const Key('network-editor'),
          height: 170,
          width: double.infinity,
          child: GestureDetector(
            onPanStart: (details) =>
                _draggedNode = _nearestNode(details.localPosition, nodes),
            onPanUpdate: (details) {
              if (_draggedNode == null) return;
              setState(
                () => _positions[_draggedNode!] =
                    _positions[_draggedNode!]! + details.delta,
              );
            },
            onPanEnd: (_) => _draggedNode = null,
            child: CustomPaint(
              painter: _NetworkPainter(
                edges: widget.edges,
                positions: _positions,
                source: widget.source,
              ),
            ),
          ),
        ),
        Text(
          'Arraste os nós para explorar as relações.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  String? _nearestNode(Offset point, List<String> nodes) {
    for (final node in nodes) {
      if ((point - _positions[node]!).distance < 28) return node;
    }
    return null;
  }
}

class _NetworkPainter extends CustomPainter {
  const _NetworkPainter({
    required this.edges,
    required this.positions,
    required this.source,
  });

  final List<InfluenceEdge> edges;
  final Map<String, Offset> positions;
  final String source;

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = RadiantColors.gold.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    for (final edge in edges) {
      final start = positions[edge.source];
      final end = positions[edge.target];
      if (start == null || end == null) continue;
      canvas.drawLine(start, end, edgePaint);
    }
    for (final entry in positions.entries) {
      final paint = Paint()
        ..color = entry.key == source
            ? RadiantColors.luminousGold
            : RadiantColors.surfaceBright;
      canvas.drawCircle(entry.value, 22, paint);
      canvas.drawCircle(
        entry.value,
        22,
        Paint()
          ..color = RadiantColors.gold
          ..style = PaintingStyle.stroke,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: const TextStyle(color: RadiantColors.ivory, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        entry.value - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => true;
}
