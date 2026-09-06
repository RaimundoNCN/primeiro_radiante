import 'dart:math' as math;
import 'dart:ui';

class CircleScore {
  const CircleScore({
    required this.accepted,
    required this.score,
    required this.closure,
    required this.aspectRatio,
    required this.angularCoverage,
    required this.radialError,
    required this.directionConsistency,
  });

  const CircleScore.rejected()
    : accepted = false,
      score = 0,
      closure = double.infinity,
      aspectRatio = 0,
      angularCoverage = 0,
      radialError = double.infinity,
      directionConsistency = 0;

  final bool accepted;
  final double score;
  final double closure;
  final double aspectRatio;
  final double angularCoverage;
  final double radialError;
  final double directionConsistency;
}

class CircleRecognizer {
  const CircleRecognizer({
    this.minimumPoints = 24,
    this.minimumLength = 120,
    this.minimumDiameter = 72,
    this.maximumClosure = 0.30,
    this.minimumAspectRatio = 0.65,
    this.maximumRadialError = 0.32,
    this.minimumScore = 0.72,
  });

  final int minimumPoints;
  final double minimumLength;
  final double minimumDiameter;
  final double maximumClosure;
  final double minimumAspectRatio;
  final double maximumRadialError;
  final double minimumScore;

  CircleScore evaluate(List<Offset> points) {
    if (points.length < minimumPoints) {
      return const CircleScore.rejected();
    }

    var minX = points.first.dx;
    var maxX = points.first.dx;
    var minY = points.first.dy;
    var maxY = points.first.dy;
    var length = 0.0;
    var centerX = 0.0;
    var centerY = 0.0;

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
      centerX += point.dx;
      centerY += point.dy;
      if (index > 0) {
        length += (point - points[index - 1]).distance;
      }
    }

    final width = maxX - minX;
    final height = maxY - minY;
    final diameter = (width + height) / 2;
    if (length < minimumLength ||
        width < minimumDiameter ||
        height < minimumDiameter ||
        diameter == 0) {
      return const CircleScore.rejected();
    }

    final center = Offset(centerX / points.length, centerY / points.length);
    final radii = points.map((point) => (point - center).distance).toList();
    final meanRadius = radii.reduce((a, b) => a + b) / radii.length;
    if (meanRadius == 0) {
      return const CircleScore.rejected();
    }

    final radialVariance =
        radii
            .map((radius) => math.pow(radius - meanRadius, 2).toDouble())
            .reduce((a, b) => a + b) /
        radii.length;
    final radialError = math.sqrt(radialVariance) / meanRadius;
    final closure = (points.last - points.first).distance / diameter;
    final aspectRatio = math.min(width, height) / math.max(width, height);

    var signedAngle = 0.0;
    var absoluteAngle = 0.0;
    var previousAngle = math.atan2(
      points.first.dy - center.dy,
      points.first.dx - center.dx,
    );
    for (final point in points.skip(1)) {
      final angle = math.atan2(point.dy - center.dy, point.dx - center.dx);
      var delta = angle - previousAngle;
      while (delta > math.pi) {
        delta -= 2 * math.pi;
      }
      while (delta < -math.pi) {
        delta += 2 * math.pi;
      }
      signedAngle += delta;
      absoluteAngle += delta.abs();
      previousAngle = angle;
    }

    final angularCoverage = signedAngle.abs();
    final directionConsistency = absoluteAngle == 0
        ? 0.0
        : (signedAngle.abs() / absoluteAngle).clamp(0.0, 1.0);
    final closureScore = (1 - closure / maximumClosure).clamp(0.0, 1.0);
    final aspectScore =
        ((aspectRatio - minimumAspectRatio) / (1 - minimumAspectRatio)).clamp(
          0.0,
          1.0,
        );
    final coverageScore = (1 - (angularCoverage - 2 * math.pi).abs() / math.pi)
        .clamp(0.0, 1.0);
    final radialScore = (1 - radialError / maximumRadialError).clamp(0.0, 1.0);
    final score =
        closureScore * 0.25 +
        aspectScore * 0.15 +
        coverageScore * 0.25 +
        radialScore * 0.25 +
        directionConsistency * 0.10;

    final accepted =
        closure <= maximumClosure &&
        aspectRatio >= minimumAspectRatio &&
        angularCoverage >= 1.6 * math.pi &&
        angularCoverage <= 2.6 * math.pi &&
        radialError <= maximumRadialError &&
        score >= minimumScore;

    return CircleScore(
      accepted: accepted,
      score: score,
      closure: closure,
      aspectRatio: aspectRatio,
      angularCoverage: angularCoverage,
      radialError: radialError,
      directionConsistency: directionConsistency,
    );
  }
}
