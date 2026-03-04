import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/rating_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════
// SearchScreen — Global Campus Directory (Real-Time Firestore)
// ═══════════════════════════════════════════════════════════════════════════
//
// Displays a real-time, searchable list of all registered students from
// the Firestore `users` collection. The logged-in user is excluded from
// the list (self-filter). Each tile includes a "Rate" button that opens
// the rating sheet pre-selected with that student.
// ═══════════════════════════════════════════════════════════════════════════

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final currentUid = currentUser?.uid ?? '';

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
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLg,
                  AppTheme.spaceLg,
                  AppTheme.spaceLg,
                  AppTheme.spaceSm,
                ),
                child: Text(
                  'Campus Directory',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // ── Search bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    hintText: 'Search by name...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceMd),

              // ── Student list (Firestore real-time) ──────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('name')
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
                          'Error loading students',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    // Self-filter: exclude logged-in user
                    // Query filter: case-insensitive name match
                    final filtered = docs.where((doc) {
                      if (doc.id == currentUid) return false;
                      if (_query.isEmpty) return true;
                      final name =
                          (doc.data() as Map<String, dynamic>)['name'] ?? '';
                      return name.toString().toLowerCase().contains(
                        _query.toLowerCase(),
                      );
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Results count ───────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceLg,
                          ),
                          child: Text(
                            '${filtered.length} student${filtered.length == 1 ? '' : 's'} found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSm),

                        // ── List ────────────────────────────────────────
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    _query.isEmpty
                                        ? 'No registered students yet'
                                        : 'No results for "$_query"',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white38,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spaceMd,
                                  ).copyWith(bottom: 100),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 2),
                                  itemBuilder: (context, index) {
                                    final doc = filtered[index];
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    final uid = doc.id;
                                    final name = (data['name'] ?? 'Unknown')
                                        .toString();
                                    final cgpa =
                                        (data['cgpa_score'] as num?)
                                            ?.toDouble() ??
                                        0.0;
                                    final reputation =
                                        (data['reputation'] as num?)
                                            ?.toDouble() ??
                                        0.0;

                                    return _StudentTile(
                                      uid: uid,
                                      name: name,
                                      cgpa: cgpa,
                                      reputation: reputation,
                                      onRate: () {
                                        HapticFeedback.selectionClick();
                                        showRatingSheet(
                                          context,
                                          preselectedName: name,
                                          preselectedUid: uid,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
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

// ── Student list tile ───────────────────────────────────────────────────────

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.uid,
    required this.name,
    required this.cgpa,
    required this.reputation,
    required this.onRate,
  });

  final String uid;
  final String name;
  final double cgpa;
  final double reputation;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repColor = AppTheme.reputationColor(reputation);

    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: 14,
      ),
      fillOpacity: 0.08,
      borderOpacity: 0.12,
      margin: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          // ── Avatar with Hero tag for transition animation ────────
          Hero(
            tag: 'avatar_$uid',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  _initials(name),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),

          // Name + CGPA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'CGPA ${cgpa.toStringAsFixed(1)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ── Reputation badge ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: repColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              reputation.toStringAsFixed(2),
              style: theme.textTheme.titleMedium?.copyWith(
                color: repColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // ── Rate button ─────────────────────────────────────────
          IconButton(
            icon: const Icon(
              Icons.star_half_rounded,
              color: AppTheme.warning,
              size: 24,
            ),
            onPressed: onRate,
            tooltip: 'Rate $name',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.warning.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
