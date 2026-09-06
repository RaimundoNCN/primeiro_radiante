import 'package:flutter/material.dart';

import '../../../core/observatory/trend_observatory.dart';
import '../../../core/persistence/analysis_database.dart';
import '../../../core/theme/radiant_theme.dart';
import '../../documentation/presentation/documentation_screen.dart';

class TrendObservatoryScreen extends StatefulWidget {
  const TrendObservatoryScreen({super.key});

  @override
  State<TrendObservatoryScreen> createState() => _TrendObservatoryScreenState();
}

class _TrendObservatoryScreenState extends State<TrendObservatoryScreen> {
  final _periods = TextEditingController(text: '80');
  final _simulations = TextEditingController(text: '100');
  final _eventPeriod = TextEditingController(text: '35');
  final _eventImpact = TextEditingController(text: '-18');
  final _eventName = TextEditingController(text: 'Choque de recursos');
  final _groups = TextEditingController(
    text:
        'Núcleo:1000000:0.74:80:0.2|Fronteira:400000:0.58:55:0.35|Colônias:700000:0.66:65:0.25',
  );
  final _institutions = TextEditingController(
    text: 'Ciência:0.9:0.05|Comércio:0.7:0.08|Administração:0.8:0.12',
  );
  final _name = TextEditingController(text: 'Observação inicial');
  ObservatoryResult? _result;
  String? _error;

  @override
  void dispose() {
    _periods.dispose();
    _simulations.dispose();
    _eventPeriod.dispose();
    _eventImpact.dispose();
    _eventName.dispose();
    _groups.dispose();
    _institutions.dispose();
    _name.dispose();
    super.dispose();
  }

  void _observe() {
    try {
      final periods = int.parse(_periods.text.trim());
      final simulations = int.parse(_simulations.text.trim());
      final event = HistoricalEvent(
        period: int.parse(_eventPeriod.text.trim()),
        name: _eventName.text.trim(),
        impact: double.parse(_eventImpact.text.trim()),
      );
      final observed = const TrendObservatory().observe(
        groups: _parseGroups(),
        institutions: _parseInstitutions(),
        events: [event],
        periods: periods,
        simulations: simulations,
        seed: 42,
      );
      setState(() {
        _result = observed;
        _error = null;
      });
      assert(observed.history.isNotEmpty);
    } on Object catch (error) {
      setState(() => _error = 'Revise os parâmetros: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Observatório de tendências'),
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
        ],
      ),
      body: ListView(
        key: const Key('observatory-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'HISTÓRIA AGREGADA',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: RadiantColors.gold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Observar sem profetizar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'O modelo trabalha com grupos, instituições e incerteza. Não prevê indivíduos.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _field(_periods, 'Períodos históricos'),
          _field(_simulations, 'Simulações Monte Carlo'),
          _field(_eventPeriod, 'Período do evento'),
          _field(_eventImpact, 'Impacto do evento'),
          _field(_eventName, 'Nome do evento'),
          _field(
            _groups,
            'Grupos (nome:população:estabilidade:recursos:resistência | ...)',
          ),
          _field(
            _institutions,
            'Instituições (nome:influência:decadência | ...)',
          ),
          _field(_name, 'Nome do experimento'),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('observe-trends'),
            onPressed: _observe,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Observar trajetória'),
          ),
          if (result != null)
            OutlinedButton.icon(
              key: const Key('save-observatory'),
              onPressed: () => _save(result),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar observação localmente'),
            ),
          if (_error != null)
            _panel('Entrada inválida', _error!, Icons.warning_amber_rounded),
          if (result != null) ...[
            _panel(
              'Explicador histórico',
              result.explanation,
              Icons.auto_awesome_rounded,
            ),
            _metricGrid(result),
            _TrendChart(history: result.history),
            _panel(
              'Crises de Seldon',
              result.crises.isEmpty
                  ? 'Nenhum limiar cruzado.'
                  : result.crises
                        .map(
                          (crisis) =>
                              'Período ${crisis.period}: ${crisis.reason} (${crisis.severity.toStringAsFixed(2)})',
                        )
                        .join('\n'),
              Icons.warning_rounded,
            ),
            _panel(
              'Cenários contrafactuais',
              'O evento selecionado alterou a estabilidade final em ${result.counterfactualDelta.toStringAsFixed(3)} em relação à linha sem eventos.',
              Icons.alt_route_rounded,
            ),
            _panel(
              'Instituições e ideias',
              '${result.institutionInfluence.entries.map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(2)}').join('  •  ')}\n\nAlcance estimado:\n${result.ideaReach.entries.map((entry) => '${entry.key}: ${entry.value.toStringAsFixed(0)}').join('  •  ')}',
              Icons.hub_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    ),
  );

  List<CollectiveGroup> _parseGroups() => _groups.text.split('|').map((entry) {
    final parts = entry.trim().split(':');
    if (parts.length != 5) throw const FormatException('grupo inválido');
    return CollectiveGroup(
      name: parts[0].trim(),
      population: double.parse(parts[1]),
      stability: double.parse(parts[2]),
      resources: double.parse(parts[3]),
      ideaResistance: double.parse(parts[4]),
    );
  }).toList();

  List<InstitutionState> _parseInstitutions() =>
      _institutions.text.split('|').map((entry) {
        final parts = entry.trim().split(':');
        if (parts.length != 3) {
          throw const FormatException('instituição inválida');
        }
        return InstitutionState(
          name: parts[0].trim(),
          influence: double.parse(parts[1]),
          decay: double.parse(parts[2]),
        );
      }).toList();

  Future<void> _save(ObservatoryResult result) async {
    await AnalysisDatabase.instance.saveObservatory(
      run: ObservatoryRunRecord(
        name: _name.text.trim(),
        input: {
          'groups': _groups.text,
          'institutions': _institutions.text,
          'event': _eventName.text,
          'periods': _periods.text,
        },
        result: {
          'p10': result.p10,
          'p50': result.p50,
          'p90': result.p90,
          'crises': result.crises.length,
          'explanation': result.explanation,
        },
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Observação salva localmente.')),
      );
    }
  }

  Widget _panel(String title, String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 14),
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

  Widget _metricGrid(ObservatoryResult result) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      children: [
        _metric('Períodos', '${result.history.length - 1}'),
        _metric('Crises', '${result.crises.length}'),
        _metric('P10', result.p10.toStringAsFixed(2)),
        _metric('P50', result.p50.toStringAsFixed(2)),
        _metric('P90', result.p90.toStringAsFixed(2)),
      ],
    ),
  );

  Widget _metric(String label, String value) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: RadiantColors.surfaceBright,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.history});

  final List<TrendPoint> history;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: SizedBox(
      height: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RadiantColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: CustomPaint(painter: _TrendPainter(history)),
      ),
    ),
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.history);

  final List<TrendPoint> history;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    final grid = Paint()
      ..color = RadiantColors.muted.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    void draw(Iterable<double> values, Color color) {
      final list = values.toList();
      final path = Path();
      for (var index = 0; index < list.length; index++) {
        final point = Offset(
          size.width * index / (list.length - 1),
          size.height * (1 - list[index].clamp(0, 1)),
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    draw(history.map((point) => point.stability), RadiantColors.luminousGold);
    draw(
      history.map((point) => (point.resources / 100).clamp(0, 1)),
      Colors.lightBlueAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      history != oldDelegate.history;
}
