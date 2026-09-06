import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:primeiro_radiante/features/radiant_gate/domain/circle_recognizer.dart';

void main() {
  const recognizer = CircleRecognizer();

  test('aceita um círculo anti-horário', () {
    final result = recognizer.evaluate(_circlePoints(clockwise: false));

    expect(result.accepted, isTrue);
    expect(result.score, greaterThanOrEqualTo(0.72));
  });

  test('aceita um círculo horário', () {
    final result = recognizer.evaluate(_circlePoints(clockwise: true));

    expect(result.accepted, isTrue);
  });

  test('rejeita uma linha longa', () {
    final points = List.generate(50, (index) => Offset(index * 5, index * 0.4));

    final result = recognizer.evaluate(points);

    expect(result.accepted, isFalse);
  });

  test('rejeita um círculo aberto demais', () {
    final points = List.generate(60, (index) {
      final angle = 1.35 * math.pi * index / 59;
      return Offset(160 + math.cos(angle) * 80, 240 + math.sin(angle) * 80);
    });

    final result = recognizer.evaluate(points);

    expect(result.accepted, isFalse);
  });
}

List<Offset> _circlePoints({required bool clockwise}) {
  return List.generate(73, (index) {
    final direction = clockwise ? -1 : 1;
    final angle = direction * 2 * math.pi * index / 72;
    return Offset(160 + math.cos(angle) * 80, 240 + math.sin(angle) * 80);
  });
}
