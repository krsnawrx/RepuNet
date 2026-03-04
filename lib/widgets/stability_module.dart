import 'package:flutter/material.dart';

import '../providers/reputation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_counter.dart';
import '../widgets/glassmorphic_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// StabilityModule — PRD §6 Step 3 (Smoothing Logic Visualisation)
// ═══════════════════════════════════════════════════════════════════════════
//
// Visualises the Exponential Moving Average (EMA) smoothing:
//
//   newReputation = oldRep × 0.7 + calculatedRep × 0.3
//
// The segmented progress bar fills to `smoothingAnchor` (default 70%)
// to show how much of the current score is "anchored" to history.
//
// Why this matters (PRD §7 — Manipulation Protections):
//   • A single bad review shifts the score by at most 30%.
//   • Consistent ratings over time are required for meaningful change.
//   • This is the core anti-review-bombing defence.
//
// Below the progress bar, two stat cards show:
//   1. Credibility weight (0.6×cgpa + 0.4×rep, capped at 1.0)
//   2. Total recent interaction count
// ═══════════════════════════════════════════════════════════════════════════

class StabilityModule extends StatelessWidget {
  const StabilityModule({super.key, required this.rep});

  /// The current reputation state from [reputationProvider].
  final ReputationState rep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Stability bar card ──────────────────────────────────────────
        GlassmorphicCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'System Stability',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(rep.smoothingAnchor * 100).toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),

              // Explanation
              Text(
                'Your score is ${(rep.smoothingAnchor * 100).toInt()}% '
                'anchored to history. New ratings can only shift '
                'it by ${((1 - rep.smoothingAnchor) * 100).toInt()}% '
                'at a time.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // ── Smoothing progress bar ────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: rep.smoothingAnchor,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accentLight],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),

              // Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '← Historical (${(rep.smoothingAnchor * 100).toInt()}%)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accent,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'New (${((1 - rep.smoothingAnchor) * 100).toInt()}%) →',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Credibility + stats row ──────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: GlassmorphicCard(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppTheme.success,
                      size: 22,
                    ),
                    const SizedBox(height: 8),
                    AnimatedCounter(
                      value: rep.credibility,
                      fractionDigits: 2,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Credibility',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: GlassmorphicCard(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.people_rounded,
                      color: AppTheme.accentLight,
                      size: 22,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${rep.recentInteractions.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Recent Ratings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
