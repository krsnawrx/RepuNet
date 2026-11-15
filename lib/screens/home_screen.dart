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
import 'posts_feed_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

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

              double parseDouble(dynamic val) {
                if (val is num) return val.toDouble();
                if (val is String) return double.tryParse(val) ?? 0.0;
                return 0.0;
              }

              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                );
              }

              final data =
                  (userSnap.data?.data() as Map<String, dynamic>?) ?? {};
              final userName = (data['name'] as String?) ?? 'Student';
              final cgpa = parseDouble(data['cgpa_score']);
              final peerScore = parseDouble(data['peer_score']);
              final teacherScore = parseDouble(data['teacher_score']);

              final normalizedCGPA = cgpa / 10.0;

              final totalScore =
                  (peerScore * 0.5) +
                  (normalizedCGPA * 0.3) +
                  (teacherScore * 0.2);

              final credibility = ((0.6 * normalizedCGPA) + (0.4 * totalScore))
                  .clamp(0.0, 1.0);

              final repState = ReputationState(
                peerScore: peerScore,
                normalizedCGPA: normalizedCGPA,
                teacherScore: teacherScore,
                calculatedReputation: totalScore,
                finalReputation:
                    totalScore,
                smoothingAnchor: 0.7,
                credibility: credibility,
              );

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [

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

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                    ).copyWith(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        ReputationHeroCard(rep: repState),

                        StabilityModule(rep: repState),

                        const SizedBox(height: AppTheme.spaceSm),

                        _RatingsStreamFeed(uid: uid),

                        const SizedBox(height: AppTheme.spaceSm),

                        _AchievementsBanner(),
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

class _RatingsStreamFeed extends StatelessWidget {
  const _RatingsStreamFeed({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .where('toId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(5)
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

class _AchievementsBanner extends StatelessWidget {
  const _AchievementsBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PostsFeedScreen()),
        );
      },
      child: GlassmorphicCard(
        fillOpacity: 0.08,
        borderOpacity: 0.14,
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC107).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFC107),
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievement Posts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Share wins & earn credibility upvotes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
