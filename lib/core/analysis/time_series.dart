import 'dart:math' as math;

class TimeSeriesPoint {
  const TimeSeriesPoint(this.time, this.value);

  final double time;
  final double value;
}

class TimeSeriesAnalysis {
  const TimeSeriesAnalysis(this.points);

  final List<TimeSeriesPoint> points;

  List<double> movingAverage(int window) {
    if (window <= 0 || window > points.length) {
      throw ArgumentError.value(window, 'window', 'must fit the series');
    }
    return List.generate(points.length - window + 1, (index) {
      final slice = points.skip(index).take(window);
      return slice.map((point) => point.value).reduce((a, b) => a + b) / window;
    });
  }

  List<TimeSeriesPoint> linearForecast(int periods) {
    if (points.length < 2 || periods < 0) {
      throw ArgumentError(
        'At least two points and a non-negative period count are required',
      );
    }
    final meanTime =
        points.map((point) => point.time).reduce((a, b) => a + b) /
        points.length;
    final meanValue =
        points.map((point) => point.value).reduce((a, b) => a + b) /
        points.length;
    final denominator = points
        .map((point) => math.pow(point.time - meanTime, 2).toDouble())
        .reduce((a, b) => a + b);
    if (denominator == 0) {
      throw ArgumentError('Time values must not all be equal');
    }
    final slope =
        points
            .map((point) => (point.time - meanTime) * (point.value - meanValue))
            .reduce((a, b) => a + b) /
        denominator;
    final intercept = meanValue - slope * meanTime;
    final step = points.last.time - points[points.length - 2].time;
    return List.generate(periods, (index) {
      final time = points.last.time + step * (index + 1);
      return TimeSeriesPoint(time, intercept + slope * time);
    });
  }
}
