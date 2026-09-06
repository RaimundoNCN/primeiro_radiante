import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/radiant_theme.dart';
import '../domain/circle_recognizer.dart';
import '../domain/gate_state.dart';
import 'radiant_field_painter.dart';

class RadiantGateScreen extends StatefulWidget {
  const RadiantGateScreen({required this.onUnlocked, this.now, super.key});

  final VoidCallback onUnlocked;
  final Duration Function()? now;

  @override
  State<RadiantGateScreen> createState() => _RadiantGateScreenState();
}

class _RadiantGateScreenState extends State<RadiantGateScreen>
    with TickerProviderStateMixin {
  static const _tapWindow = Duration(milliseconds: 2500);
  static const _maximumTapDuration = Duration(milliseconds: 250);
  static const _minimumTapInterval = Duration(milliseconds: 80);
  static const _maximumTapInterval = Duration(milliseconds: 650);
  static const _maximumTapMovement = 18.0;

  final _recognizer = const CircleRecognizer();
  final List<Offset> _trace = [];
  final List<Offset> _fadingTrace = [];
  final List<RadiantPulse> _pulses = [];
  final Stopwatch _monotonicClock = Stopwatch();
  final Stopwatch _visualClock = Stopwatch();
  late final AnimationController _ambientController;
  late final AnimationController _entranceController;
  late final AnimationController _unlockController;
  late final Listenable _fieldAnimation;
  RadiantGatePhase _phase = RadiantGatePhase.awaitingCircle;
  int? _activePointer;
  Duration? _pointerDownAt;
  Duration? _lastTapAt;
  Offset? _pointerOrigin;
  Offset? _touch;
  double _fadingTraceBornAt = -2;
  int _tapCount = 0;
  int _failedAttempts = 0;
  bool _reduceMotion = false;
  Timer? _tapTimeout;

  @override
  void initState() {
    super.initState();
    _monotonicClock.start();
    _visualClock.start();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    )..forward();
    _unlockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fieldAnimation = Listenable.merge([
      _ambientController,
      _entranceController,
      _unlockController,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _ambientController
        ..stop(canceled: false)
        ..value = 0.18;
      _entranceController.value = 1;
    } else if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }
  }

  @override
  void dispose() {
    _tapTimeout?.cancel();
    _monotonicClock.stop();
    _visualClock.stop();
    _ambientController.dispose();
    _entranceController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_phase == RadiantGatePhase.unlocking) return;
    if (_activePointer != null && _activePointer != event.pointer) {
      _resetGate(countFailure: true);
      return;
    }

    _activePointer = event.pointer;
    _pointerDownAt = _now;
    _pointerOrigin = event.localPosition;
    setState(() {
      _touch = event.localPosition;
      _addPulse(event.localPosition, strength: 0.7);
      if (_phase == RadiantGatePhase.awaitingCircle) {
        _trace
          ..clear()
          ..add(event.localPosition);
      }
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer ||
        _phase == RadiantGatePhase.unlocking) {
      return;
    }
    setState(() {
      _touch = event.localPosition;
      if (_phase == RadiantGatePhase.awaitingCircle &&
          (_trace.isEmpty ||
              (event.localPosition - _trace.last).distance >= 4)) {
        _trace.add(event.localPosition);
      }
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer ||
        _phase == RadiantGatePhase.unlocking) {
      return;
    }
    _activePointer = null;

    if (_phase == RadiantGatePhase.awaitingCircle) {
      final score = _recognizer.evaluate(List.unmodifiable(_trace));
      if (score.accepted) {
        _beginTapSequence();
      } else {
        _resetGate(countFailure: true, preserveTouch: true);
      }
      return;
    }

    final downAt = _pointerDownAt;
    final origin = _pointerOrigin;
    if (downAt == null || origin == null) {
      _resetGate(countFailure: true);
      return;
    }
    final timestamp = _now;
    final duration = timestamp - downAt;
    final movement = (event.localPosition - origin).distance;
    final interval = _lastTapAt == null ? null : timestamp - _lastTapAt!;
    final validInterval =
        interval == null ||
        (interval >= _minimumTapInterval && interval <= _maximumTapInterval);

    if (duration <= _maximumTapDuration &&
        movement <= _maximumTapMovement &&
        validInterval) {
      _registerTap(timestamp, event.localPosition);
    } else {
      _resetGate(countFailure: true);
    }
  }

  void _beginTapSequence() {
    _tapTimeout?.cancel();
    HapticFeedback.lightImpact();
    final centroid =
        _trace.fold<Offset>(Offset.zero, (total, point) => total + point) /
        _trace.length.toDouble();
    setState(() {
      _phase = RadiantGatePhase.awaitingTaps;
      _tapCount = 0;
      _lastTapAt = null;
      _addPulse(centroid, strength: 1.35);
    });
    _tapTimeout = Timer(_tapWindow, () {
      if (mounted && _phase == RadiantGatePhase.awaitingTaps) {
        _resetGate(countFailure: true);
      }
    });
  }

  void _registerTap(Duration timestamp, Offset position) {
    HapticFeedback.selectionClick();
    setState(() {
      _tapCount += 1;
      _lastTapAt = timestamp;
      _touch = position;
      _addPulse(position, strength: 1 + _tapCount * 0.18);
    });
    if (_tapCount == 3) _unlock();
  }

  void _unlock() {
    if (_phase == RadiantGatePhase.unlocking) return;
    _tapTimeout?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _phase = RadiantGatePhase.unlocking;
      _activePointer = null;
      if (_touch case final position?) {
        _addPulse(position, strength: 1.65);
      }
    });
    if (_reduceMotion) {
      _unlockController.value = 1;
    } else {
      _unlockController.forward(from: 0);
    }
    Timer(Duration(milliseconds: _reduceMotion ? 180 : 920), () {
      if (mounted) widget.onUnlocked();
    });
  }

  void _addPulse(Offset position, {double strength = 1}) {
    _pulses.add(
      RadiantPulse(
        position: position,
        bornAt: _visualSeconds,
        strength: strength,
      ),
    );
    if (_pulses.length > 9) _pulses.removeAt(0);
  }

  Duration get _now => widget.now?.call() ?? _monotonicClock.elapsed;
  double get _visualSeconds => _visualClock.elapsedMicroseconds / 1000000;

  void _resetGate({required bool countFailure, bool preserveTouch = false}) {
    _tapTimeout?.cancel();
    if (countFailure) _failedAttempts += 1;
    setState(() {
      if (_trace.length > 1) {
        _fadingTrace
          ..clear()
          ..addAll(_trace);
        _fadingTraceBornAt = _visualSeconds;
      }
      _phase = RadiantGatePhase.awaitingCircle;
      _activePointer = null;
      _pointerDownAt = null;
      _pointerOrigin = null;
      _lastTapAt = null;
      _tapCount = 0;
      _trace.clear();
      if (!preserveTouch) _touch = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: (_) => _resetGate(countFailure: true),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: RadiantFieldPainter(
                  repaintSignal: _fieldAnimation,
                  entranceAnimation: _entranceController,
                  unlockAnimation: _unlockController,
                  elapsedSeconds: () => _visualSeconds,
                  phase: _phase,
                  trace: List.unmodifiable(_trace),
                  fadingTrace: List.unmodifiable(_fadingTrace),
                  fadingTraceBornAt: _fadingTraceBornAt,
                  touch: _touch,
                  tapCount: _tapCount,
                  pulses: List.unmodifiable(_pulses),
                  reduceMotion: _reduceMotion,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entranceController,
                    curve: const Interval(0.2, 1, curve: Curves.easeOut),
                  ),
                  child: Column(
                    children: [
                      const _GateHeader(),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.18),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Semantics(
                          key: ValueKey(_phase),
                          liveRegion: true,
                          label: _phase.instruction,
                          child: Text(
                            _phase.instruction,
                            key: const Key('gate-instruction'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: RadiantColors.ivory),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TapProgress(
                        active: _phase == RadiantGatePhase.awaitingTaps,
                        count: _tapCount,
                      ),
                      if (_failedAttempts >= 3) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Faça o traço em um único movimento ou use a entrada acessível.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextButton.icon(
                        key: const Key('accessible-unlock'),
                        onPressed: _phase == RadiantGatePhase.unlocking
                            ? null
                            : _unlock,
                        icon: const Icon(
                          Icons.accessibility_new_rounded,
                          size: 19,
                        ),
                        label: const Text('Usar entrada acessível'),
                        style: TextButton.styleFrom(
                          foregroundColor: RadiantColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateHeader extends StatelessWidget {
  const _GateHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'PRIMEIRO RADIANTE',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: RadiantColors.gold,
            letterSpacing: 4.2,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toda resposta começa\ncom uma pergunta.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w300,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _TapProgress extends StatelessWidget {
  const _TapProgress({required this.active, required this.count});

  final bool active;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final filled = active && index < count;
        return AnimatedScale(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          scale: filled ? 1.15 : 1,
          child: AnimatedContainer(
            key: Key('tap-progress-$index'),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: filled ? 23 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: filled
                  ? RadiantColors.luminousGold
                  : RadiantColors.gold.withValues(alpha: active ? 0.32 : 0.12),
              borderRadius: BorderRadius.circular(99),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: RadiantColors.luminousGold.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 9,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
