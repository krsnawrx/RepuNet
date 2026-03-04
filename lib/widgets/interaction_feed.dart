import 'package:flutter/material.dart';

import '../models/interaction.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// InteractionFeed — Recent Ratings List
// ═══════════════════════════════════════════════════════════════════════════
//
// Displays the last 5 ratings received by the current user.
// Data comes from the ReputationNotifier which streams from the `ratings`
// collection in Firestore (filtered by toUser == currentUserId).
//
// Each tile shows:
//   • Rater's initials (avatar)
//   • Rater's name
//   • Relative timestamp
//   • Star rating (1–5)
//   • Comment (if provided)
// ═══════════════════════════════════════════════════════════════════════════

class InteractionFeed extends StatelessWidget {
  const InteractionFeed({super.key, required this.interactions});

  /// The list of recent interactions to display (will show only last 5).
  final List<Interaction> interactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (interactions.isEmpty) {
      return GlassmorphicCard(
        fillOpacity: 0.06,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Text(
              'No ratings yet. Your reputation is currently\n'
              'anchored to your Academic & Faculty scores.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white38,
              ),
            ),
          ),
        ),
      );
    }

    // Show only the last 5 ratings
    final recentFive = interactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppTheme.spaceSm),
          child: Row(
            children: [
              Text(
                'Recent Ratings',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${recentFive.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rater tiles
        ...recentFive.asMap().entries.map((entry) {
          final interaction = entry.value;
          final isLast = entry.key == recentFive.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? AppTheme.spaceLg : 0),
            child: _RaterTile(interaction: interaction),
          );
        }),
      ],
    );
  }
}

// ── _RaterTile — individual rater row ───────────────────────────────────────

class _RaterTile extends StatelessWidget {
  const _RaterTile({required this.interaction});
  final Interaction interaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: 14,
      ),
      fillOpacity: 0.08,
      borderOpacity: 0.12,
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Avatar ──────────────────────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(interaction.fromUserName),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),

              // ── Name + timestamp ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interaction.fromUserName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _timeAgo(interaction.timestamp),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stars ─────────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < interaction.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i < interaction.rating
                        ? AppTheme.warning
                        : Colors.white24,
                    size: 18,
                  );
                }),
              ),
            ],
          ),

          // ── Comment (if present) ──────────────────────────────────
          if (interaction.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${interaction.comment}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
