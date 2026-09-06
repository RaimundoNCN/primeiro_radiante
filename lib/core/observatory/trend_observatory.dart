import 'dart:math' as math;

class CollectiveGroup {
  const CollectiveGroup({
    required this.name,
    required this.population,
    required this.stability,
    required this.resources,
    this.ideaResistance = 0.2,
  });

  final String name;
  final double population;
  final double stability;
  final double resources;
  final double ideaResistance;
}

class InstitutionState {
  const InstitutionState({
    required this.name,
    required this.influence,
    required this.decay,
  });

  final String name;
  final double influence;
  final double decay;
}

class HistoricalEvent {
  const HistoricalEvent({
    required this.period,
    required this.name,
    required this.impact,
  });

  final int period;
  final String name;
  final double impact;
}

class TrendPoint {
  const TrendPoint({
    required this.period,
    required this.stability,
    required this.resources,
    required this.entropy,
  });

  final int period;
  final double stability;
  final double resources;
  final double entropy;
}

class CrisisSignal {
  const CrisisSignal({
    required this.period,
    required this.title,
    required this.severity,
    required this.reason,
  });

  final int period;
  final String title;
  final double severity;
  final String reason;
}

class ObservatoryResult {
  const ObservatoryResult({
    required this.history,
    required this.crises,
    required this.finalGroups,
    required this.institutionInfluence,
    required this.ideaReach,
    required this.counterfactualDelta,
    required this.monteCarlo,
    required this.explanation,
    required this.p10,
    required this.p50,
    required this.p90,
    required this.criticalPeriod,
    required this.mostAffectedGroup,
  });

  final List<TrendPoint> history;
  final List<CrisisSignal> crises;
  final List<CollectiveGroup> finalGroups;
  final Map<String, double> institutionInfluence;
  final Map<String, double> ideaReach;
  final double counterfactualDelta;
  final List<double> monteCarlo;
  final String explanation;
  final double p10;
  final double p50;
  final double p90;
  final int? criticalPeriod;
  final String? mostAffectedGroup;
}

class ObservatoryComparison {
  const ObservatoryComparison({
    required this.stabilityDelta,
    required this.resourceDelta,
    required this.crisisDelta,
  });

  final double stabilityDelta;
  final double resourceDelta;
  final int crisisDelta;
}

class TrendObservatory {
  const TrendObservatory();

  ObservatoryResult observe({
    required List<CollectiveGroup> groups,
    required List<InstitutionState> institutions,
    required List<HistoricalEvent> events,
    required int periods,
    int simulations = 100,
    int seed = 0,
  }) {
    if (groups.isEmpty || periods < 1 || simulations < 1) {
      throw ArgumentError('Groups, periods and simulations must be positive');
    }
    final baseline = _run(groups, institutions, events, periods, seed);
    final withoutEvents = _run(groups, institutions, const [], periods, seed);
    final monteCarlo = [
      for (var index = 0; index < simulations; index++)
        _run(
          groups,
          institutions,
          events,
          periods,
          seed + index + 1,
        ).history.last.stability,
    ];
    final finalGroups = _projectGroups(groups, baseline.history.last);
    final institutionInfluence = _institutionInfluence(
      institutions,
      baseline.history.last,
    );
    final ideaReach = _ideaReach(
      finalGroups,
      institutions,
      baseline.history.last,
    );
    final finalStability = baseline.history.last.stability;
    final explanation = _explain(baseline, institutionInfluence, ideaReach);
    final percentiles = _percentiles(monteCarlo);
    final criticalPeriod = baseline.crises.isEmpty
        ? null
        : baseline.crises.first.period;
    final affected = _mostAffectedGroup(groups, baseline.history.last);
    return ObservatoryResult(
      history: baseline.history,
      crises: baseline.crises,
      finalGroups: finalGroups,
      institutionInfluence: institutionInfluence,
      ideaReach: ideaReach,
      counterfactualDelta:
          finalStability - withoutEvents.history.last.stability,
      monteCarlo: monteCarlo,
      explanation: explanation,
      p10: percentiles[0],
      p50: percentiles[1],
      p90: percentiles[2],
      criticalPeriod: criticalPeriod,
      mostAffectedGroup: affected,
    );
  }

  ObservatoryComparison compare(
    ObservatoryResult first,
    ObservatoryResult second,
  ) => ObservatoryComparison(
    stabilityDelta:
        second.history.last.stability - first.history.last.stability,
    resourceDelta: second.history.last.resources - first.history.last.resources,
    crisisDelta: second.crises.length - first.crises.length,
  );

  _RunResult _run(
    List<CollectiveGroup> groups,
    List<InstitutionState> institutions,
    List<HistoricalEvent> events,
    int periods,
    int seed,
  ) {
    final random = math.Random(seed);
    var stability =
        groups.map((group) => group.stability).reduce((a, b) => a + b) /
        groups.length;
    var resources =
        groups.map((group) => group.resources).reduce((a, b) => a + b) /
        groups.length;
    final history = <TrendPoint>[];
    final crises = <CrisisSignal>[];
    for (var period = 0; period <= periods; period++) {
      final eventImpact = events
          .where((event) => event.period == period)
          .fold<double>(0, (sum, event) => sum + event.impact);
      final institutionalSupport =
          institutions.fold<double>(
            0,
            (sum, institution) =>
                sum + institution.influence * (1 - institution.decay),
          ) /
          math.max(1, institutions.length);
      resources = math.max(
        0,
        resources *
                (1 +
                    0.01 * institutionalSupport +
                    (random.nextDouble() - 0.5) * 0.04) +
            eventImpact,
      );
      stability =
          (stability +
                  institutionalSupport * 0.015 -
                  eventImpact * 0.12 -
                  (resources < 25 ? 0.04 : 0))
              .clamp(0, 1);
      final entropy = (1 - stability) + (resources / 100).clamp(0, 1) * 0.2;
      history.add(
        TrendPoint(
          period: period,
          stability: stability,
          resources: resources,
          entropy: entropy,
        ),
      );
      if (stability < 0.35 || resources < 15 || eventImpact <= -10) {
        crises.add(
          CrisisSignal(
            period: period,
            title: 'Ponto de ruptura',
            severity: 1 - stability,
            reason: resources < 15
                ? 'recursos em queda'
                : 'estabilidade abaixo do limiar',
          ),
        );
      }
    }
    return _RunResult(history: history, crises: crises);
  }

  List<CollectiveGroup> _projectGroups(
    List<CollectiveGroup> groups,
    TrendPoint last,
  ) => [
    for (final group in groups)
      CollectiveGroup(
        name: group.name,
        population: group.population * (1 + last.resources / 10_000),
        stability: last.stability,
        resources: last.resources,
      ),
  ];

  Map<String, double> _institutionInfluence(
    List<InstitutionState> institutions,
    TrendPoint last,
  ) => {
    for (final institution in institutions)
      institution.name:
          institution.influence * last.stability * (1 - institution.decay),
  };

  Map<String, double> _ideaReach(
    List<CollectiveGroup> groups,
    List<InstitutionState> institutions,
    TrendPoint last,
  ) {
    final multiplier =
        institutions.fold<double>(
          0,
          (sum, institution) => sum + institution.influence,
        ) /
        math.max(1, institutions.length);
    return {
      for (final group in groups)
        group.name:
            (group.population *
                    last.stability *
                    multiplier *
                    (1 - group.ideaResistance) /
                    100)
                .clamp(0, group.population),
    };
  }

  List<double> _percentiles(List<double> values) {
    final sorted = [...values]..sort();
    double at(double position) =>
        sorted[(position * (sorted.length - 1)).round()];
    return [at(0.1), at(0.5), at(0.9)];
  }

  String? _mostAffectedGroup(List<CollectiveGroup> groups, TrendPoint last) {
    if (groups.isEmpty) return null;
    return (groups.toList()..sort((a, b) => a.stability.compareTo(b.stability)))
        .first
        .name;
  }

  String _explain(
    _RunResult result,
    Map<String, double> institutions,
    Map<String, double> ideas,
  ) {
    final strongest = institutions.entries.isEmpty
        ? 'nenhuma instituição'
        : (institutions.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
    final reach = ideas.values.fold<double>(0, (sum, value) => sum + value);
    return 'A trajetória terminou com estabilidade ${result.history.last.stability.toStringAsFixed(2)}. '
        'A instituição mais influente foi $strongest; o alcance estimado da ideia foi ${reach.toStringAsFixed(1)} pessoas agregadas. '
        '${result.crises.isEmpty ? 'Nenhum limiar crítico foi cruzado.' : '${result.crises.length} sinais de crise foram detectados.'}';
  }
}

class _RunResult {
  const _RunResult({required this.history, required this.crises});

  final List<TrendPoint> history;
  final List<CrisisSignal> crises;
}
