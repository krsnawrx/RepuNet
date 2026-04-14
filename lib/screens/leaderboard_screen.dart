import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';
import 'student_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LeaderboardScreen — Real-Time Reputation Rankings
// ═══════════════════════════════════════════════════════════════════════════
//
// Streams the `users` collection ordered by `reputation` DESC.
// Filters out teachers (role == 'teacher').
//
// Tier System:
//   0.0–0.2  Newcomer      (Grey)
//   0.2–0.4  Rising Star   (#448AFF Blue)
//   0.4–0.6  Trusted Peer  (#00E676 Green)
//   0.6–0.8  Community Pillar (#AA00FF Purple)
//   0.8–1.0  Elite         (#FFC107 Gold)
//
// Top 3 positions get Gold / Silver / Bronze medal icons.
// ═══════════════════════════════════════════════════════════════════════════

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUid = ref.watch(authServiceProvider).currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy, AppTheme.navyLight, AppTheme.navyMedium],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLg,
                  AppTheme.spaceLg,
                  AppTheme.spaceLg,
                  AppTheme.spaceSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ranked by reputation score',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spaceSm),

              // ── Leaderboard list ────────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('reputation', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading leaderboard',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // Filter out teachers
                    final students = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['role'] != 'teacher';
                    }).toList();

                    if (students.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 56,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Text(
                              'No students ranked yet',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMd,
                      ).copyWith(bottom: 100), // clear BottomAppBar
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final doc = students[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final uid = doc.id;
                        final name =
                            (data['name'] ?? 'Unknown').toString();
                        final username =
                            (data['username'] ?? '').toString();
                        final reputation =
                            (data['reputation'] as num?)?.toDouble() ?? 0.0;
                        final rank = index + 1;
                        final isCurrentUser = uid == currentUid;

                        return _LeaderboardTile(
                          rank: rank,
                          uid: uid,
                          name: name,
                          username: username,
                          reputation: reputation,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _LeaderboardTile — Individual ranking row
// ═══════════════════════════════════════════════════════════════════════════

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.uid,
    required this.name,
    required this.username,
    required this.reputation,
    required this.isCurrentUser,
  });

  final int rank;
  final String uid;
  final String name;
  final String username;
  final double reputation;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = _TierInfo.fromScore(reputation);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StudentProfileScreen(uid: uid)),
        );
      },
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: 14,
        ),
        fillOpacity: isCurrentUser ? 0.18 : 0.08,
        borderOpacity: isCurrentUser ? 0.30 : 0.12,
        margin: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            // ── Rank indicator (medal or number) ────────────────────
            SizedBox(
              width: 36,
              child: _buildRankWidget(context),
            ),
            const SizedBox(width: AppTheme.spaceSm),

            // ── Avatar ──────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tier.color.withValues(alpha: 0.15),
                border: Border.all(
                  color: tier.color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tier.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),

            // ── Name + username ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: isCurrentUser
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            'YOU',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: AppTheme.spaceSm),

            // ── Score + Tier badge ───────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Score
                Text(
                  reputation.toStringAsFixed(2),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tier.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tier.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    tier.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tier.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds medal icons for top 3, numeric rank for others.
  Widget _buildRankWidget(BuildContext context) {
    final theme = Theme.of(context);

    if (rank <= 3) {
      final IconData icon = Icons.emoji_events_rounded;
      final Color medalColor;
      switch (rank) {
        case 1:
          medalColor = const Color(0xFFFFC107); // Gold
          break;
        case 2:
          medalColor = const Color(0xFFB0BEC5); // Silver
          break;
        case 3:
          medalColor = const Color(0xFFCD7F32); // Bronze
          break;
        default:
          medalColor = Colors.white38;
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: medalColor, size: 22),
          Text(
            '#$rank',
            style: theme.textTheme.labelSmall?.copyWith(
              color: medalColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        '#$rank',
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white38,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _TierInfo — Maps reputation score to tier label + colour
// ═══════════════════════════════════════════════════════════════════════════

class _TierInfo {
  final String label;
  final Color color;

  const _TierInfo({required this.label, required this.color});

  /// Tier thresholds per spec:
  ///   0.0–0.2: Newcomer (Grey)
  ///   0.2–0.4: Rising Star (#448AFF Blue)
  ///   0.4–0.6: Trusted Peer (#00E676 Green)
  ///   0.6–0.8: Community Pillar (#AA00FF Purple)
  ///   0.8–1.0: Elite (#FFC107 Gold)
  factory _TierInfo.fromScore(double score) {
    if (score >= 0.8) {
      return const _TierInfo(
        label: 'ELITE',
        color: Color(0xFFFFC107),
      );
    }
    if (score >= 0.6) {
      return const _TierInfo(
        label: 'PILLAR',
        color: Color(0xFFAA00FF),
      );
    }
    if (score >= 0.4) {
      return const _TierInfo(
        label: 'TRUSTED',
        color: Color(0xFF00E676),
      );
    }
    if (score >= 0.2) {
      return const _TierInfo(
        label: 'RISING',
        color: Color(0xFF448AFF),
      );
    }
    return _TierInfo(
      label: 'NEW',
      color: Colors.grey.shade500,
    );
  }
}
