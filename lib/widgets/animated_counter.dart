import 'package:flutter/material.dart';

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

  final double value;

  final TextStyle? style;

  final int fractionDigits;

  final Duration duration;

  final Curve curve;

  final String prefix;

  final String suffix;

  @override
  Widget build(BuildContext context) {

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
