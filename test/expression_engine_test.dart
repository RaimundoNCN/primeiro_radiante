import 'package:flutter_test/flutter_test.dart';
import 'package:primeiro_radiante/core/math/expression_engine.dart';
import 'package:primeiro_radiante/core/math/units.dart';

void main() {
  test('avalia expressão com variáveis, precedência e função segura', () {
    final engine = const ExpressionEngine();
    expect(engine.evaluate('2 + x * sqrt(9)', {'x': 4}), 14);
  });

  test('rejeita símbolo desconhecido e divisão por zero', () {
    const engine = ExpressionEngine();
    expect(
      () => engine.evaluate('x + 1', const {}),
      throwsA(isA<UnknownSymbolFailure>()),
    );
    expect(
      () => engine.evaluate('4 / 0', const {}),
      throwsA(isA<DivisionByZeroFailure>()),
    );
  });

  test('converte e soma unidades compatíveis', () {
    expect(const UnitValue(2, 'km').convertTo('m').value, 2000);
    expect(
      const UnitValue(2, 'm') + const UnitValue(3, 'm'),
      const UnitValue(5, 'm'),
    );
    expect(
      () => const UnitValue(2, 'm') + const UnitValue(3, 's'),
      throwsArgumentError,
    );
  });
}
