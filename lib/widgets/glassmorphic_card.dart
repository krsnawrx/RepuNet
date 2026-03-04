import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// GlassmorphicCard
// ═══════════════════════════════════════════════════════════════════════════
//
// A reusable glassmorphism-style card that uses [BackdropFilter] to create
// a frosted-glass effect. The visual recipe:
//
//   1. ClipRRect                → clips the blur to rounded corners.
//   2. BackdropFilter           → applies a Gaussian blur to everything
//                                  *behind* this widget (sigma 12–16).
//   3. Semi-transparent fill    → white @ 12-18 % opacity over the blur.
//   4. Subtle luminous border   → white @ 20 % for the glass-edge feel.
//
// Usage:
//   GlassmorphicCard(
//     child: Text('Hello'),
//   )
//
// On screens with a dark/gradient background the frosted tint is very
// visible; on lighter backgrounds it degrades gracefully to a soft card.
// ═══════════════════════════════════════════════════════════════════════════

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

  /// The content inside the glass card.
  final Widget child;

  /// Optional inner padding (defaults to 20 px all around).
  final EdgeInsetsGeometry? padding;

  /// Optional outer margin.
  final EdgeInsetsGeometry? margin;

  /// Corner radius (defaults to [AppTheme.radiusLg] = 20).
  final double? borderRadius;

  /// Gaussian blur strength applied behind the card.
  /// Higher = more frosted; 10–18 works well in practice.
  final double blurSigma;

  /// Opacity of the white fill layer (0.0–1.0).
  final double fillOpacity;

  /// Opacity of the white border (0.0–1.0).
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.radiusLg;

    // ── Performance: RepaintBoundary ──────────────────────────────────
    // At 120Hz the render loop runs every ~8.3ms. Without a repaint
    // boundary, the BackdropFilter blur shader re-executes on EVERY frame
    // even if the card content hasn't changed. Wrapping in RepaintBoundary
    // tells the engine to cache this subtree as its own compositing layer
    // and only repaint when the child actually changes.
    return RepaintBoundary(
      child: Container(
        margin:
            margin ?? const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
        child: ClipRRect(
          // Step 1: Clip so the blur doesn't bleed past rounded corners.
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            // Step 2: Blur everything behind this widget.
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                // Step 3: Semi-transparent white fill over the blur.
                color: Colors.white.withValues(alpha: fillOpacity),
                borderRadius: BorderRadius.circular(radius),
                // Step 4: Luminous border that catches the light.
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
