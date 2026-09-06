import 'dart:math' as math;

sealed class ExpressionFailure implements Exception {
  const ExpressionFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExpressionSyntaxFailure extends ExpressionFailure {
  const ExpressionSyntaxFailure(super.message);
}

class UnknownSymbolFailure extends ExpressionFailure {
  const UnknownSymbolFailure(super.message);
}

class InvalidFunctionFailure extends ExpressionFailure {
  const InvalidFunctionFailure(super.message);
}

class DivisionByZeroFailure extends ExpressionFailure {
  const DivisionByZeroFailure() : super('divisão por zero');
}

sealed class ExpressionNode {
  const ExpressionNode();

  double evaluate(Map<String, double> variables);
}

class NumberNode extends ExpressionNode {
  const NumberNode(this.value);

  final double value;

  @override
  double evaluate(Map<String, double> variables) => value;
}

class VariableNode extends ExpressionNode {
  const VariableNode(this.name);

  final String name;

  @override
  double evaluate(Map<String, double> variables) {
    final value = variables[name];
    if (value == null) {
      throw UnknownSymbolFailure('símbolo desconhecido: $name');
    }
    return value;
  }
}

class BinaryNode extends ExpressionNode {
  const BinaryNode(this.operator, this.left, this.right);

  final String operator;
  final ExpressionNode left;
  final ExpressionNode right;

  @override
  double evaluate(Map<String, double> variables) {
    final a = left.evaluate(variables);
    final b = right.evaluate(variables);
    return switch (operator) {
      '+' => a + b,
      '-' => a - b,
      '*' => a * b,
      '/' => b == 0 ? throw const DivisionByZeroFailure() : a / b,
      '^' => math.pow(a, b).toDouble(),
      _ => throw InvalidFunctionFailure('operador não permitido: $operator'),
    };
  }
}

class FunctionNode extends ExpressionNode {
  const FunctionNode(this.name, this.arguments);

  final String name;
  final List<ExpressionNode> arguments;

  @override
  double evaluate(Map<String, double> variables) {
    final values = arguments
        .map((argument) => argument.evaluate(variables))
        .toList();
    double one() {
      if (values.length != 1) {
        throw InvalidFunctionFailure('$name espera um argumento');
      }
      return values.first;
    }

    return switch (name) {
      'abs' => one().abs(),
      'sqrt' => math.sqrt(one()),
      'ln' => math.log(one()),
      'exp' => math.exp(one()),
      'sin' => math.sin(one()),
      'cos' => math.cos(one()),
      'tan' => math.tan(one()),
      'min' =>
        values.isEmpty
            ? throw InvalidFunctionFailure('$name exige argumentos')
            : values.reduce(math.min),
      'max' =>
        values.isEmpty
            ? throw InvalidFunctionFailure('$name exige argumentos')
            : values.reduce(math.max),
      _ => throw InvalidFunctionFailure('função não permitida: $name'),
    };
  }
}

class ExpressionEngine {
  const ExpressionEngine();

  ExpressionNode parse(String source) => _Parser(source).parse();

  double evaluate(String source, Map<String, double> variables) =>
      parse(source).evaluate(variables);
}

class _Parser {
  _Parser(this.source);

  final String source;
  var index = 0;

  ExpressionNode parse() {
    final result = _expression();
    _skipSpaces();
    if (index != source.length) {
      throw ExpressionSyntaxFailure('token inesperado em $index');
    }
    return result;
  }

  ExpressionNode _expression() => _binary(_term, {'+', '-'});

  ExpressionNode _term() => _binary(_power, {'*', '/'});

  ExpressionNode _power() => _binary(_unary, {'^'});

  ExpressionNode _unary() {
    _skipSpaces();
    if (_match('+')) return _unary();
    if (_match('-')) return BinaryNode('*', const NumberNode(-1), _unary());
    return _primary();
  }

  ExpressionNode _primary() {
    _skipSpaces();
    if (_match('(')) {
      final value = _expression();
      _expect(')');
      return value;
    }
    if (index < source.length && (source[index].contains(RegExp(r'[0-9.]')))) {
      return _number();
    }
    final name = _identifier();
    _skipSpaces();
    if (_match('(')) {
      final arguments = <ExpressionNode>[];
      _skipSpaces();
      if (!_match(')')) {
        do {
          arguments.add(_expression());
        } while (_match(','));
        _expect(')');
      }
      return FunctionNode(name, arguments);
    }
    return VariableNode(name);
  }

  ExpressionNode _number() {
    final start = index;
    while (index < source.length &&
        RegExp(r'[0-9.eE+-]').hasMatch(source[index])) {
      if ((source[index] == '+' || source[index] == '-') &&
          index > start &&
          source[index - 1] != 'e' &&
          source[index - 1] != 'E') {
        break;
      }
      index++;
    }
    final value = double.tryParse(source.substring(start, index));
    if (value == null) throw ExpressionSyntaxFailure('número inválido');
    return NumberNode(value);
  }

  String _identifier() {
    _skipSpaces();
    final start = index;
    while (index < source.length &&
        RegExp(r'[A-Za-z_]').hasMatch(source[index])) {
      index++;
    }
    if (start == index) {
      throw ExpressionSyntaxFailure('identificador esperado em $index');
    }
    return source.substring(start, index);
  }

  ExpressionNode _binary(
    ExpressionNode Function() next,
    Set<String> operators,
  ) {
    var left = next();
    while (true) {
      _skipSpaces();
      if (index >= source.length || !operators.contains(source[index])) {
        return left;
      }
      final operator = source[index++];
      left = BinaryNode(operator, left, next());
    }
  }

  bool _match(String value) {
    _skipSpaces();
    if (source.startsWith(value, index)) {
      index += value.length;
      return true;
    }
    return false;
  }

  void _expect(String value) {
    if (!_match(value)) {
      throw ExpressionSyntaxFailure('esperado "$value" em $index');
    }
  }

  void _skipSpaces() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
  }
}
