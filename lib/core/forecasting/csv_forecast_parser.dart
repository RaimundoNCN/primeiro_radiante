import 'forecast_validation.dart';

class ForecastCsvParser {
  const ForecastCsvParser();

  List<ForecastObservation> observations(String source) {
    return _rows(source, 2).map((row) {
      return ForecastObservation(
        period: int.parse(row[0]),
        value: double.parse(row[1]),
      );
    }).toList();
  }

  List<ForecastInterval> forecasts(String source) {
    return _rows(source, 4).map((row) {
      return ForecastInterval(
        period: int.parse(row[0]),
        p10: double.parse(row[1]),
        p50: double.parse(row[2]),
        p90: double.parse(row[3]),
      );
    }).toList();
  }

  List<List<String>> _rows(String source, int columns) {
    final lines = source
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      throw const FormatException('nenhum dado informado');
    }
    final start = _looksLikeHeader(lines.first) ? 1 : 0;
    final rows = <List<String>>[];
    for (final line in lines.skip(start)) {
      final row = line.split(',').map((value) => value.trim()).toList();
      if (row.length != columns) {
        throw FormatException('cada linha deve ter $columns colunas');
      }
      rows.add(row);
    }
    if (rows.isEmpty) {
      throw const FormatException('nenhum dado após o cabeçalho');
    }
    return rows;
  }

  bool _looksLikeHeader(String line) => RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(line);
}
