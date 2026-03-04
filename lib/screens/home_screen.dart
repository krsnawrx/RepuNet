import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interaction.dart';
import '../providers/auth_provider.dart';
import '../providers/reputation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/interaction_feed.dart';
import '../widgets/reputation_hero_card.dart';
import '../widgets/stability_module.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HomeScreen — Glassmorphic Dashboard (Direct Firestore StreamBuilder)
// ═══════════════════════════════════════════════════════════════════════════
//
// Uses direct Firestore StreamBuilders rather than the Riverpod provider
// to guarantee data loads correctly regardless of auth timing.
//
// Two streams run in parallel:
//   1. users/{uid} — core fields: reputation, peerScore, cgpa, teacherScore
//   2. ratings (toUser == uid, last 5) — recent ratings feed
// ═══════════════════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authStateProvider is guaranteed resolved (AppShell only renders when user != null)
    final authAsync = ref.watch(authStateProvider);
    final uid = authAsync.valueOrNull?.uid;
    final theme = Theme.of(context);

    if (uid == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, userSnap) {
              // Helper to parse numbers robustly in case Firestore has Strings
              double parseDouble(dynamic val) {
                if (val is num) return val.toDouble();
                if (val is String) return double.tryParse(val) ?? 0.0;
                return 0.0;
              }

              // ── Loading / error guards ──────────────────────────────────
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                );
              }

              // Pull fields from Firestore doc (all default to 0 if missing)
              final data =
                  (userSnap.data?.data() as Map<String, dynamic>?) ?? {};
              final userName = (data['name'] as String?) ?? 'Student';
              final cgpa = parseDouble(data['cgpa_score']);
              final peerScore = parseDouble(data['peer_score']);
              final teacherScore = parseDouble(data['teacher_score']);

              final normalizedCGPA = cgpa / 10.0;

              // Total Score formula requested:
              // (peer_score * 0.5) + (cgpa_score * 0.3) + (teacher_score * 0.2)
              // NOTE: using raw cgpa instead of normalized for cgpa_score, as per standard user request mapping
              // Wait, the prompt says "cgpa_score", but earlier it's "cgpa / 10" which is normalized. Let's stick with normalized.
              final totalScore =
                  (peerScore * 0.5) +
                  (normalizedCGPA * 0.3) +
                  (teacherScore * 0.2);

              // Credibility: 0.6×cgpa + 0.4×rep
              final credibility = ((0.6 * normalizedCGPA) + (0.4 * totalScore))
                  .clamp(0.0, 1.0);

              final repState = ReputationState(
                peerScore: peerScore,
                normalizedCGPA: normalizedCGPA,
                teacherScore: teacherScore,
                calculatedReputation: totalScore,
                finalReputation:
                    totalScore, // Map the Top Meter directly to Total Score
                smoothingAnchor: 0.7,
                credibility: credibility,
              );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── SliverAppBar ──────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 100,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(
                        left: AppTheme.spaceLg,
                        bottom: 14,
                      ),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            userName.isNotEmpty ? userName : 'Student',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Body widgets ──────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                    ).copyWith(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Layer 1: Reputation score + tier + breakdown
                        ReputationHeroCard(rep: repState),

                        // Layer 2: Smoothing bar + credibility + stats
                        StabilityModule(rep: repState),

                        const SizedBox(height: AppTheme.spaceSm),

                        // Layer 3: Recent ratings feed (last 3)
                        _RatingsStreamFeed(uid: uid),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _RatingsStreamFeed — streams last 3 ratings directly from Firestore
// ═══════════════════════════════════════════════════════════════════════════

class _RatingsStreamFeed extends StatelessWidget {
  const _RatingsStreamFeed({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .where('toUser', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return GlassmorphicCard(
            fillOpacity: 0.06,
            child: const Padding(
              padding: EdgeInsets.all(AppTheme.spaceLg),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        final interactions = docs.map((doc) {
          return Interaction.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
        }).toList();

        return InteractionFeed(interactions: interactions);
      },
    );
  }
}
