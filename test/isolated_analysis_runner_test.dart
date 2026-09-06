import 'package:flutter_test/flutter_test.dart';
import 'package:primeiro_radiante/core/runtime/isolated_analysis_runner.dart';

int _square(int value) => value * value;

void main() {
  test('executa uma operação isolada e retorna o resultado', () async {
    final result = await const IsolatedAnalysisRunner().run(12, _square);
    expect(result, 144);
  });
}
