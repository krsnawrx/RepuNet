import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/rating_sheet.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'student_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AppShell — Two-Tab Navigation Shell
// ═══════════════════════════════════════════════════════════════════════════
//
// The root scaffold that hosts:
//
//   1. An [IndexedStack] body with two tabs:
//        [0] Dashboard  (HomeScreen)
//        [1] Profile    (ProfileScreen)
//
//   2. A [BottomAppBar] with a [CircularNotchedRectangle] shape,
//      creating the premium notch cutout for the FAB.
//
//   3. A centre-docked [FloatingActionButton] that opens a full-screen
//      Campus Directory modal with search + Firestore student list.
//
//   4. [extendBody: true] so the gradient backgrounds from each
//      screen extend behind the translucent bottom bar.
// ═══════════════════════════════════════════════════════════════════════════

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // Two screens stay alive via IndexedStack.
  static const _screens = <Widget>[HomeScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ── extendBody lets the gradient bleed under the bottom bar ────
      extendBody: true,

      // ── Body: IndexedStack preserves state across tab switches ─────
      body: IndexedStack(index: _currentIndex, children: _screens),

      // ── Centre-docked FAB (opens full-screen Campus Directory) ─────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCampusDirectoryModal(context),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ── Bottom App Bar with notch ─────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppTheme.navy,
        elevation: 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Left side: Dashboard ─────────────────────────────
            _NavBarButton(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),

            // ── Right side: Profile ─────────────────────────────
            _NavBarButton(
              icon: Icons.person_rounded,
              label: 'Profile',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Full-Screen Campus Directory Modal
// ═══════════════════════════════════════════════════════════════════════════

void _showCampusDirectoryModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CampusDirectorySheet(),
  );
}

class _CampusDirectorySheet extends ConsumerStatefulWidget {
  const _CampusDirectorySheet();

  @override
  ConsumerState<_CampusDirectorySheet> createState() =>
      _CampusDirectorySheetState();
}

class _CampusDirectorySheetState extends ConsumerState<_CampusDirectorySheet> {
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        color: AppTheme.navy.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spaceMd),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // ── Title ──────────────────────────────────────────────
              Text(
                'Campus Directory',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Find and rate registered students',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // ── Search bar ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg,
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
                    hintText: 'Search by username...',
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

              // ── Real-time Firestore student list ───────────────────
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

                    // Self-filter + search query filter + hide teachers
                    final filtered = docs.where((doc) {
                      if (doc.id == currentUid) return false;
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['role'] == 'teacher') return false;

                      if (_query.isEmpty) return true;
                      final username = data['username'] ?? '';
                      return username.toString().toLowerCase().contains(
                        _query.toLowerCase(),
                      );
                    }).toList();

                    // Results count
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    horizontal: AppTheme.spaceLg,
                                  ).copyWith(bottom: AppTheme.spaceLg),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 4),
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
                                    final repColor = AppTheme.reputationColor(
                                      reputation,
                                    );

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                StudentProfileScreen(uid: uid),
                                          ),
                                        );
                                      },
                                      child: GlassmorphicCard(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spaceMd,
                                          vertical: 14,
                                        ),
                                        fillOpacity: 0.08,
                                        borderOpacity: 0.12,
                                        margin: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppTheme.accent
                                                    .withValues(alpha: 0.15),
                                                border: Border.all(
                                                  color: AppTheme.accent
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  _initials(name),
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: AppTheme.accent,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppTheme.spaceMd,
                                            ),

                                            // Name + CGPA
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                  ),
                                                  Text(
                                                    'CGPA ${cgpa.toStringAsFixed(1)}',
                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: Colors.white38,
                                                          fontSize: 12,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Reputation badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: repColor.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppTheme.radiusSm,
                                                    ),
                                              ),
                                              child: Text(
                                                reputation.toStringAsFixed(2),
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: repColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),

                                            // Rate button
                                            IconButton(
                                              icon: const Icon(
                                                Icons.star_half_rounded,
                                                color: AppTheme.warning,
                                                size: 24,
                                              ),
                                              onPressed: () {
                                                HapticFeedback.selectionClick();
                                                Navigator.of(context).pop();
                                                showRatingSheet(
                                                  context,
                                                  preselectedName: name,
                                                  preselectedUid: uid,
                                                );
                                              },
                                              tooltip: 'Rate $name',
                                              style: IconButton.styleFrom(
                                                backgroundColor: AppTheme
                                                    .warning
                                                    .withValues(alpha: 0.12),
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                minimumSize: const Size(36, 36),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _NavBarButton — custom bottom nav button for the notched bar
// ═══════════════════════════════════════════════════════════════════════════

class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.accent : Colors.white38;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
