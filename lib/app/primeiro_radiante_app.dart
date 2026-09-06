import 'package:flutter/material.dart';

import '../core/theme/radiant_theme.dart';
import '../features/home/presentation/radiant_home_screen.dart';
import '../features/radiant_gate/presentation/radiant_gate_screen.dart';

class PrimeiroRadianteApp extends StatefulWidget {
  const PrimeiroRadianteApp({this.gateClock, super.key});

  final Duration Function()? gateClock;

  @override
  State<PrimeiroRadianteApp> createState() => _PrimeiroRadianteAppState();
}

class _PrimeiroRadianteAppState extends State<PrimeiroRadianteApp> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Primeiro Radiante',
      debugShowCheckedModeBanner: false,
      theme: buildRadiantTheme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 850),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
        child: _isUnlocked
            ? const RadiantHomeScreen(key: ValueKey('radiant-home'))
            : RadiantGateScreen(
                key: const ValueKey('radiant-gate'),
                now: widget.gateClock,
                onUnlocked: () => setState(() => _isUnlocked = true),
              ),
      ),
    );
  }
}
