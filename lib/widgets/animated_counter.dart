import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AnimatedCounter
// ═══════════════════════════════════════════════════════════════════════════
//
// Smoothly animates a numeric value from its previous display value to a
// new target value over [duration] using a [Tween<double>] animation.
//
// This is used on the dashboard to make the reputation score "count up"
// when the screen loads or when the score changes in real time, giving
// the UI a polished, dynamic feel.
//
// The [fractionDigits] parameter controls decimal precision (default 2).
// The optional [prefix] and [suffix] are rendered around the number.
//
// Example:
//   AnimatedCounter(
//     value: 0.76,            // target value
//     style: TextStyle(...),  // how to render
//     duration: Duration(milliseconds: 900),
//   )
// ═══════════════════════════════════════════════════════════════════════════

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.fractionDigits = 2,
    this.duration = const Duration(milliseconds: 900),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
  });

  /// The target numeric value to animate to.
  final double value;

  /// Text style applied to the rendered number.
  final TextStyle? style;

  /// Number of decimal places to display.
  final int fractionDigits;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Optional text before the number (e.g., "★ ").
  final String prefix;

  /// Optional text after the number (e.g., " / 1.00").
  final String suffix;

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder automatically interpolates between the old
    // and new [value] whenever it changes. No AnimationController needed.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        return Text(
          '$prefix${animatedValue.toStringAsFixed(fractionDigits)}$suffix',
          style: style,
        );
      },
    );
  }
}
