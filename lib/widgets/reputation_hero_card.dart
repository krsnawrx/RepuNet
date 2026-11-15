import 'package:flutter/material.dart';

import '../providers/reputation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_counter.dart';
import '../widgets/glassmorphic_card.dart';

class ReputationHeroCard extends StatelessWidget {
  const ReputationHeroCard({super.key, required this.rep});

  final ReputationState rep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        children: [

          Text(
            'REPUTATION SCORE',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white60,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),

          AnimatedCounter(
            value: rep.finalReputation,
            fractionDigits: 2,
            duration: const Duration(milliseconds: 1200),
            style: theme.textTheme.displayLarge?.copyWith(
              color: AppTheme.reputationColor(rep.finalReputation),
              fontWeight: FontWeight.w800,
              fontSize: 64,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.reputationColor(
                rep.finalReputation,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              _tierLabel(rep.finalReputation),
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.reputationColor(rep.finalReputation),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: AppTheme.spaceMd,
            runSpacing: AppTheme.spaceSm,
            children: [
              _MiniStat(
                label: 'Peer',
                value: rep.peerScore,
                weight: '50%',
                color: AppTheme.accent,
              ),
              _MiniStat(
                label: 'CGPA',
                value: rep.normalizedCGPA,
                weight: '30%',
                color: AppTheme.accentLight,
              ),
              _MiniStat(
                label: 'Teacher',
                value: rep.teacherScore,
                weight: '20%',
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _tierLabel(double score) {
    if (score >= 0.75) return '★ High Standing';
    if (score >= 0.40) return '● Moderate';
    return '▽ Needs Improvement';
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.weight,
    required this.color,
  });
  final String label;
  final double value;
  final String weight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCounter(
          value: value,
          fractionDigits: 2,
          duration: const Duration(milliseconds: 1000),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 12),
        ),
        Text(
          weight,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
