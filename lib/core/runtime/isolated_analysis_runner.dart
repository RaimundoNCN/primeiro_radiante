import 'dart:async';
import 'dart:isolate';

class IsolatedAnalysisRunner {
  const IsolatedAnalysisRunner();

  Future<T> run<T, A>(
    A argument,
    FutureOr<T> Function(A argument) computation,
  ) {
    return Isolate.run(() => computation(argument));
  }
}
