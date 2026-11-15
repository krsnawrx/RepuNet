import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma = 14.0,
    this.fillOpacity = 0.14,
    this.borderOpacity = 0.20,
  });

  final Widget child;

  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;

  final double? borderRadius;

  final double blurSigma;

  final double fillOpacity;

  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.radiusLg;

    return RepaintBoundary(
      child: Container(
        margin:
            margin ?? const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
        child: ClipRRect(

          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(

            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(

                color: Colors.white.withValues(alpha: fillOpacity),
                borderRadius: BorderRadius.circular(radius),

                border: Border.all(
                  color: Colors.white.withValues(alpha: borderOpacity),
                  width: 1.2,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
