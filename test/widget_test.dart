import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primeiro_radiante/app/primeiro_radiante_app.dart';

void main() {
  testWidgets('a entrada acessível abre o Núcleo', (tester) async {
    await tester.pumpWidget(const PrimeiroRadianteApp());

    expect(find.text('PRIMEIRO RADIANTE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('accessible-unlock')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.byKey(const Key('home-title')), findsOneWidget);
    expect(find.text('Novo cálculo'), findsOneWidget);
  });

  testWidgets('Núcleo abre e pesquisa a documentação', (tester) async {
    await tester.pumpWidget(const PrimeiroRadianteApp());
    await tester.tap(find.byKey(const Key('accessible-unlock')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 750));

    await tester.tap(find.byTooltip('Documentação'));
    await tester.pumpAndSettle();
    expect(find.text('Documentação'), findsOneWidget);
    expect(find.text('Como começar'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('documentation-search')),
      'Markov',
    );
    await tester.pump();
    expect(find.text('Cadeia de Markov'), findsOneWidget);
    expect(find.text('Simulação de cenário'), findsNothing);
  });

  testWidgets('Núcleo abre a bancada e executa uma análise', (tester) async {
    await tester.pumpWidget(const PrimeiroRadianteApp());
    await tester.tap(find.byKey(const Key('accessible-unlock')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 750));

    await tester.tap(find.text('Novo cálculo'));
    await tester.pumpAndSettle();
    expect(find.text('Bancada de análise'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('analysis-scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('run-analysis')));
    await tester.pump();
    expect(find.text('Leitura do Radiante'), findsOneWidget);
    expect(find.textContaining('Estado final:'), findsOneWidget);

    await tester.tap(find.byKey(const Key('run-analysis')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('analysis-scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(find.text('Comparação da sessão'), findsOneWidget);
    expect(find.text('2 execuções mantidas nesta sessão'), findsOneWidget);
  });

  testWidgets('Núcleo abre o Observatório de tendências', (tester) async {
    await tester.pumpWidget(const PrimeiroRadianteApp());
    await tester.tap(find.byKey(const Key('accessible-unlock')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 750));

    await tester.tap(find.text('Visualização'));
    await tester.pumpAndSettle();
    expect(find.text('Observatório de tendências'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('observatory-scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('observe-trends')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('observatory-scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(find.text('Explicador histórico'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('observatory-scroll')),
      const Offset(0, -500),
    );
    await tester.pump();
    expect(find.text('Crises de Seldon'), findsOneWidget);
  });

  testWidgets('Núcleo abre a validação de previsões', (tester) async {
    await tester.pumpWidget(const PrimeiroRadianteApp());
    await tester.tap(find.byKey(const Key('accessible-unlock')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.tap(find.text('Validação'));
    await tester.pumpAndSettle();
    expect(find.text('Validação de previsões'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('forecast-validation-scroll')),
      const Offset(0, -350),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('validate-forecast')));
    await tester.pump();
    await tester.drag(
      find.byKey(const Key('forecast-validation-scroll')),
      const Offset(0, -400),
    );
    await tester.pump();
    expect(find.text('Confiabilidade'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calibrate-forecast')));
    await tester.pump();
    expect(find.text('Calibração aplicada'), findsOneWidget);
  });

  testWidgets('círculo seguido de três toques abre o Núcleo', (tester) async {
    var now = Duration.zero;
    await tester.pumpWidget(PrimeiroRadianteApp(gateClock: () => now));
    await tester.pump();

    const center = Offset(400, 300);
    const radius = 90.0;
    final gesture = await tester.startGesture(center + const Offset(radius, 0));
    for (var index = 1; index <= 64; index++) {
      final angle = 2 * math.pi * index / 64;
      await gesture.moveTo(
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      );
      await tester.pump(const Duration(milliseconds: 4));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Círculo reconhecido. Dê três toques'), findsOneWidget);

    for (var index = 0; index < 3; index++) {
      final tap = await tester.startGesture(center, pointer: index + 2);
      now += const Duration(milliseconds: 20);
      await tester.pump(const Duration(milliseconds: 20));
      await tap.up();
      now += const Duration(milliseconds: 120);
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.text('O Núcleo está respondendo'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.byKey(const Key('home-title')), findsOneWidget);
  });

  testWidgets('portal e Núcleo funcionam em 320 px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PrimeiroRadianteApp());
    expect(find.byKey(const Key('gate-instruction')), findsOneWidget);

    await tester.tap(find.byKey(const Key('accessible-unlock')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 750));

    expect(find.byKey(const Key('home-title')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
