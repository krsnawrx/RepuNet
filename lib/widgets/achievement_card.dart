import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement_post.dart';
import '../providers/auth_provider.dart';
import '../providers/post_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AchievementCard — Glassmorphic post card with credibility upvote
// ═══════════════════════════════════════════════════════════════════════════
//
// Displays a single AchievementPost in the dark glassmorphic style:
//   - Category icon + label badge
//   - Author name + time ago
//   - Title + description
//   - Weighted score display + upvote toggle button
//
// The upvote button changes color when the current user has already voted.
// ═══════════════════════════════════════════════════════════════════════════

class AchievementCard extends ConsumerWidget {
  const AchievementCard({
    super.key,
    required this.post,
  });

  final AchievementPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final currentUid = currentUser?.uid ?? '';
    final hasVoted = post.hasUpvoted(currentUid);
    final isSelf = post.authorId == currentUid;

    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      fillOpacity: 0.10,
      borderOpacity: 0.14,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Category badge + Timestamp ──────────────────────
          Row(
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _categoryColor(post.category).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(post.category),
                      color: _categoryColor(post.category),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.category.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _categoryColor(post.category),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (post.timestamp != null)
                Text(
                  _timeAgo(post.timestamp!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Row 2: Author avatar + name ────────────────────────────
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                post.authorName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Title ──────────────────────────────────────────────────
          Text(
            post.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.3,
            ),
          ),

          // ── Description ────────────────────────────────────────────
          if (post.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ── Row 3: Score display + Upvote button ───────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                // Weighted Score
                Icon(
                  Icons.insights_rounded,
                  color: AppTheme.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Score: ${post.weightedScore.toStringAsFixed(1)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                // Upvoter count
                Text(
                  '${post.upvoters.length} vote${post.upvoters.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                // Upvote Button
                _UpvoteButton(
                  hasVoted: hasVoted,
                  isSelf: isSelf,
                  onPressed: isSelf
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(postActionProvider.notifier)
                              .toggleUpvote(postId: post.id);
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  IconData _categoryIcon(PostCategory category) {
    switch (category) {
      case PostCategory.hackathon:
        return Icons.code_rounded;
      case PostCategory.project:
        return Icons.rocket_launch_rounded;
      case PostCategory.research:
        return Icons.science_rounded;
      case PostCategory.certification:
        return Icons.workspace_premium_rounded;
    }
  }

  Color _categoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.hackathon:
        return const Color(0xFF3A86FF); // Vivid blue
      case PostCategory.project:
        return const Color(0xFF06D6A0); // Teal green
      case PostCategory.research:
        return const Color(0xFFFF6B6B); // Coral
      case PostCategory.certification:
        return const Color(0xFFFFC107); // Gold
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _UpvoteButton — Animated upvote toggle
// ═══════════════════════════════════════════════════════════════════════════

class _UpvoteButton extends StatelessWidget {
  const _UpvoteButton({
    required this.hasVoted,
    required this.isSelf,
    this.onPressed,
  });

  final bool hasVoted;
  final bool isSelf;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isSelf
        ? Colors.white12
        : hasVoted
            ? AppTheme.success
            : Colors.white38;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: hasVoted ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasVoted
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_alt_outlined,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                hasVoted ? 'Voted' : 'Upvote',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
