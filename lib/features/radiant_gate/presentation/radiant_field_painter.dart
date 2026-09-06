import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/radiant_theme.dart';
import '../domain/gate_state.dart';

class RadiantPulse {
  const RadiantPulse({
    required this.position,
    required this.bornAt,
    this.strength = 1,
  });

  final Offset position;
  final double bornAt;
  final double strength;
}

class RadiantFieldPainter extends CustomPainter {
  RadiantFieldPainter({
    required Listenable repaintSignal,
    required this.entranceAnimation,
    required this.unlockAnimation,
    required this.elapsedSeconds,
    required this.phase,
    required this.trace,
    required this.fadingTrace,
    required this.fadingTraceBornAt,
    required this.touch,
    required this.tapCount,
    required this.pulses,
    required this.reduceMotion,
  }) : super(repaint: repaintSignal);

  final Animation<double> entranceAnimation;
  final Animation<double> unlockAnimation;
  final double Function() elapsedSeconds;
  final RadiantGatePhase phase;
  final List<Offset> trace;
  final List<Offset> fadingTrace;
  final double fadingTraceBornAt;
  final Offset? touch;
  final int tapCount;
  final List<RadiantPulse> pulses;
  final bool reduceMotion;

  double _elapsed = 0;
  double _time = 0;

  @override
  void paint(Canvas canvas, Size size) {
    _elapsed = elapsedSeconds();
    _time = reduceMotion ? 0 : _elapsed * 0.34;
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final entrance = Curves.easeOutCubic.transform(entranceAnimation.value);
    final unlock = Curves.easeInCubic.transform(unlockAnimation.value);
    final interactionEnergy = (tapCount / 3).clamp(0.0, 1.0);

    _drawBackground(canvas, rect, center, entrance);
    _drawDust(canvas, size, center, entrance, unlock);
    _drawOrbits(canvas, size, center, entrance, interactionEnergy, unlock);
    final nodes = _createNodes(size, center, entrance, unlock);
    _drawConstellation(canvas, nodes, entrance, interactionEnergy, unlock);
    _drawEnergyPackets(canvas, nodes, entrance, unlock);
    _drawCore(canvas, size, center, entrance, interactionEnergy, unlock);
    _drawFadingTrace(canvas);
    _drawTrace(canvas);
    _drawTouchField(canvas, size);
    _drawUnlockWave(canvas, size, center, unlock);
    _drawVignette(canvas, rect);
  }

  void _drawBackground(
    Canvas canvas,
    Rect rect,
    Offset center,
    double entrance,
  ) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101A17),
            RadiantColors.voidBlack,
            Color(0xFF020403),
          ],
          stops: [0, 0.58, 1],
        ).createShader(rect),
    );

    final motion = reduceMotion ? 0.0 : 1.0;
    final auroraOne =
        center +
        Offset(
          math.cos(_time * 0.21) * rect.width * 0.24 * motion,
          math.sin(_time * 0.17) * rect.height * 0.18 * motion,
        );
    final auroraTwo =
        center +
        Offset(
          math.sin(_time * 0.13) * rect.width * 0.31 * motion,
          math.cos(_time * 0.19) * rect.height * 0.24 * motion,
        );
    _drawAurora(
      canvas,
      auroraOne,
      math.max(rect.width, rect.height) * 0.52,
      RadiantColors.gold.withValues(alpha: 0.055 * entrance),
    );
    _drawAurora(
      canvas,
      auroraTwo,
      math.max(rect.width, rect.height) * 0.46,
      const Color(0xFF174C3C).withValues(alpha: 0.11 * entrance),
    );
  }

  void _drawAurora(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _drawDust(
    Canvas canvas,
    Size size,
    Offset center,
    double entrance,
    double unlock,
  ) {
    final motion = reduceMotion ? 0.0 : 1.0;
    for (var index = 0; index < 88; index++) {
      final seedX = ((index * 73) % 101) / 101;
      final seedY = ((index * 47 + 19) % 103) / 103;
      final depth = 0.25 + (index % 9) / 11;
      final driftX =
          math.sin(_time * (0.04 + depth * 0.05) + index) * 7 * depth * motion;
      final driftY =
          math.cos(_time * (0.03 + depth * 0.04) + index * 0.7) *
          5 *
          depth *
          motion;
      var position = Offset(
        seedX * size.width + driftX,
        seedY * size.height + driftY,
      );
      position = Offset.lerp(center, position, entrance)!;
      if (unlock > 0) {
        position = center + (position - center) * (1 + unlock * 1.9);
      }
      final twinkle = reduceMotion
          ? 0.55
          : math.sin(_time * (0.6 + depth) + index * 1.7) * 0.5 + 0.5;
      canvas.drawCircle(
        position,
        0.45 + depth * 0.9,
        Paint()
          ..color = RadiantColors.luminousGold.withValues(
            alpha: (0.08 + twinkle * 0.26) * entrance * (1 - unlock),
          ),
      );
    }
  }

  void _drawOrbits(
    Canvas canvas,
    Size size,
    Offset center,
    double entrance,
    double energy,
    double unlock,
  ) {
    final baseRadius = math.min(size.width, size.height) * 0.23;
    for (var ring = 0; ring < 4; ring++) {
      final radius =
          baseRadius * (0.65 + ring * 0.36) * entrance * (1 + unlock * 1.2);
      if (radius <= 0) continue;
      final rotation = reduceMotion
          ? ring * 0.34
          : _time * (ring.isEven ? 0.035 : -0.026) + ring * 0.34;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.scale(1, 0.62 + ring * 0.045);
      final orbitPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring == 0 ? 1.1 : 0.65
        ..color = RadiantColors.gold.withValues(
          alpha: (0.09 + energy * 0.07) * entrance * (1 - unlock * 0.65),
        );
      canvas.drawCircle(Offset.zero, radius, orbitPaint);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        _time * (ring.isEven ? 0.7 : -0.55),
        math.pi * (0.12 + ring * 0.035),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.7
          ..color = RadiantColors.luminousGold.withValues(
            alpha: (0.24 + energy * 0.3) * entrance * (1 - unlock),
          ),
      );
      canvas.restore();
    }
  }

  List<Offset> _createNodes(
    Size size,
    Offset center,
    double entrance,
    double unlock,
  ) {
    const count = 52;
    final fieldRadius = math.min(size.width, size.height) * 0.39;
    final positions = <Offset>[];
    final motion = reduceMotion ? 0.0 : 1.0;

    for (var index = 0; index < count; index++) {
      final depth = 0.18 + ((index * 37) % 83) / 100;
      final direction = index.isEven ? 1.0 : -1.0;
      final angle = index * 2.399963 + _time * 0.026 * direction * motion;
      final wobble = math.sin(_time * 0.34 + index * 0.83) * 7 * motion;
      final radius = fieldRadius * depth + wobble;
      var position =
          center +
          Offset(math.cos(angle) * radius, math.sin(angle) * radius * 1.16);
      final delay = index / count * 0.32;
      final nodeEntrance = ((entrance - delay) / (1 - delay)).clamp(0.0, 1.0);
      position = Offset.lerp(
        center,
        position,
        Curves.easeOutBack.transform(nodeEntrance),
      )!;
      if (unlock > 0) {
        position = center + (position - center) * (1 + unlock * 1.8);
      }

      final pointer = touch;
      if (pointer != null && unlock == 0 && !reduceMotion) {
        final distance = (pointer - position).distance;
        final influence = (1 - distance / 190).clamp(0.0, 1.0);
        position += (pointer - position) * influence * 0.075;
      }
      positions.add(position);
    }
    return positions;
  }

  void _drawConstellation(
    Canvas canvas,
    List<Offset> nodes,
    double entrance,
    double energy,
    double unlock,
  ) {
    final fade = entrance * (1 - unlock * 0.72);
    for (var index = 0; index < nodes.length; index++) {
      final first = nodes[index];
      final second = nodes[(index + 7) % nodes.length];
      final brightness = reduceMotion
          ? 0.5
          : math.sin(_time * 0.47 + index * 0.71) * 0.5 + 0.5;
      canvas.drawLine(
        first,
        second,
        Paint()
          ..strokeWidth = 0.55 + brightness * 0.35
          ..color = RadiantColors.gold.withValues(
            alpha: (0.035 + brightness * 0.07 + energy * 0.035) * fade,
          ),
      );
      if (index % 4 == 0) {
        canvas.drawLine(
          first,
          nodes[(index + 17) % nodes.length],
          Paint()
            ..strokeWidth = 0.5
            ..color = RadiantColors.gold.withValues(alpha: 0.035 * fade),
        );
      }
    }

    for (var index = 0; index < nodes.length; index++) {
      final depth = 0.25 + (index % 8) / 10;
      final shimmer = reduceMotion
          ? 0.55
          : math.sin(_time * (0.55 + depth * 0.2) + index * 1.31) * 0.5 + 0.5;
      final radius = 0.8 + depth * 1.35 + shimmer * 0.65;
      if (index % 5 == 0) {
        canvas.drawCircle(
          nodes[index],
          radius * 4,
          Paint()..color = RadiantColors.gold.withValues(alpha: 0.025 * fade),
        );
      }
      canvas.drawCircle(
        nodes[index],
        radius,
        Paint()
          ..color = RadiantColors.luminousGold.withValues(
            alpha: (0.28 + shimmer * 0.54) * fade,
          ),
      );
    }
  }

  void _drawEnergyPackets(
    Canvas canvas,
    List<Offset> nodes,
    double entrance,
    double unlock,
  ) {
    if (reduceMotion || unlock > 0.72) return;
    for (var index = 0; index < nodes.length; index += 4) {
      final start = nodes[index];
      final end = nodes[(index + 7) % nodes.length];
      final travel =
          (_elapsed * (0.062 + (index % 3) * 0.0095) + index * 0.071) % 1;
      final position = Offset.lerp(
        start,
        end,
        Curves.easeInOut.transform(travel),
      )!;
      final alpha = entrance * (1 - unlock) * 0.75;
      canvas.drawCircle(
        position,
        6,
        Paint()..color = RadiantColors.gold.withValues(alpha: alpha * 0.07),
      );
      canvas.drawCircle(
        position,
        1.4,
        Paint()..color = RadiantColors.luminousGold.withValues(alpha: alpha),
      );
    }
  }

  void _drawCore(
    Canvas canvas,
    Size size,
    Offset center,
    double entrance,
    double energy,
    double unlock,
  ) {
    final breath = reduceMotion ? 0.5 : math.sin(_time * 0.58) * 0.5 + 0.5;
    final radius = (13 + breath * 4 + energy * 7) * entrance + unlock * 72;
    final glowRadius = radius * (3.2 + energy * 0.8);
    if (glowRadius > 0) {
      canvas.drawCircle(
        center,
        glowRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              RadiantColors.luminousGold.withValues(
                alpha: 0.19 + energy * 0.12 + unlock * 0.22,
              ),
              RadiantColors.gold.withValues(alpha: 0.035),
              Colors.transparent,
            ],
            stops: const [0, 0.38, 1],
          ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
      );
    }

    for (var ring = 0; ring < 3; ring++) {
      final ringRadius = radius + 9 + ring * 10 + energy * ring * 3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        _time * (ring.isEven ? 0.42 : -0.31) + ring,
        math.pi * (0.55 + ring * 0.17),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.25 - ring * 0.18
          ..color = RadiantColors.luminousGold.withValues(
            alpha: (0.34 - ring * 0.07 + energy * 0.16) * entrance,
          ),
      );
    }

    canvas.drawCircle(
      center,
      math.max(0, radius),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                RadiantColors.ivory.withValues(alpha: 0.94),
                RadiantColors.luminousGold.withValues(alpha: 0.48),
                RadiantColors.gold.withValues(alpha: 0.05),
              ],
              stops: const [0, 0.18, 1],
            ).createShader(
              Rect.fromCircle(center: center, radius: math.max(1, radius)),
            ),
    );
  }

  void _drawTrace(Canvas canvas) {
    if (trace.length < 2) return;
    final path = _pathFor(
      trace,
      close: phase != RadiantGatePhase.awaitingCircle,
    );
    final bounds = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = phase == RadiantGatePhase.awaitingCircle ? 8 : 11
        ..color = RadiantColors.gold.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = phase == RadiantGatePhase.awaitingCircle ? 2.4 : 3.3
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            RadiantColors.gold,
            RadiantColors.ivory,
            RadiantColors.luminousGold,
          ],
          transform: GradientRotation(_time * 0.18),
        ).createShader(bounds.inflate(1)),
    );
  }

  void _drawFadingTrace(Canvas canvas) {
    final fadingTraceAge = ((_elapsed - fadingTraceBornAt) / 1.1).clamp(
      0.0,
      1.0,
    );
    if (fadingTrace.length < 2 || fadingTraceAge >= 1) return;
    final alpha = math.pow(1 - fadingTraceAge, 2).toDouble();
    final path = _pathFor(fadingTrace);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2 + fadingTraceAge * 5
        ..color = RadiantColors.gold.withValues(alpha: alpha * 0.48)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          3 + fadingTraceAge * 9,
        ),
    );
  }

  Path _pathFor(List<Offset> points, {bool close = false}) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (close) path.close();
    return path;
  }

  void _drawTouchField(Canvas canvas, Size size) {
    for (final pulse in pulses) {
      final age = ((_elapsed - pulse.bornAt) / 1.15).clamp(0.0, 1.0);
      if (age >= 1) continue;
      final eased = Curves.easeOutCubic.transform(age);
      final alpha = math.pow(1 - age, 2).toDouble() * pulse.strength;
      canvas.drawCircle(
        pulse.position,
        12 + eased * math.min(size.width, size.height) * 0.24,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * (1 - age) + 0.3
          ..color = RadiantColors.luminousGold.withValues(
            alpha: (alpha * 0.46).clamp(0.0, 1.0),
          ),
      );
    }

    if (touch case final position?) {
      final breathing = reduceMotion ? 0.5 : math.sin(_time * 1.3) * 0.5 + 0.5;
      canvas.drawCircle(
        position,
        15 + breathing * 6,
        Paint()
          ..shader = RadialGradient(
            colors: [
              RadiantColors.luminousGold.withValues(alpha: 0.18),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: position, radius: 24)),
      );
    }
  }

  void _drawUnlockWave(Canvas canvas, Size size, Offset center, double unlock) {
    if (unlock <= 0) return;
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final waveRadius = Curves.easeOutCubic.transform(unlock) * maxRadius * 0.7;
    canvas.drawCircle(
      center,
      waveRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1 - unlock) + 0.4
        ..color = RadiantColors.luminousGold.withValues(
          alpha: (1 - unlock) * 0.62,
        ),
    );
    canvas.drawCircle(
      center,
      maxRadius * unlock,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                RadiantColors.luminousGold.withValues(alpha: unlock * 0.18),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: maxRadius * unlock),
            ),
    );
  }

  void _drawVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.86,
          colors: [Colors.transparent, Color(0xB3050706)],
          stops: [0.52, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant RadiantFieldPainter oldDelegate) =>
      oldDelegate.entranceAnimation != entranceAnimation ||
      oldDelegate.unlockAnimation != unlockAnimation ||
      oldDelegate.phase != phase ||
      oldDelegate.trace != trace ||
      oldDelegate.fadingTrace != fadingTrace ||
      oldDelegate.fadingTraceBornAt != fadingTraceBornAt ||
      oldDelegate.touch != touch ||
      oldDelegate.tapCount != tapCount ||
      oldDelegate.pulses != pulses ||
      oldDelegate.reduceMotion != reduceMotion;
}
