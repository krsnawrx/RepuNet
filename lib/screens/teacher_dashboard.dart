import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';
import 'student_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TeacherDashboard
// ═══════════════════════════════════════════════════════════════════════════

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _TeacherStudentsTab(),
    _TeacherProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.navyMedium,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _TeacherStudentsTab
// ═══════════════════════════════════════════════════════════════════════════

class _TeacherStudentsTab extends StatefulWidget {
  const _TeacherStudentsTab();

  @override
  State<_TeacherStudentsTab> createState() => _TeacherStudentsTabState();
}

class _TeacherStudentsTabState extends State<_TeacherStudentsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedCourse;
  String? _selectedBranch;
  String? _selectedYear;
  bool _sortHighToLow = true;

  final Map<String, List<String>> _courseYears = {
    'BTech': ['1', '2', '3', '4'],
    'BSc': ['1', '2', '3'],
    'BBA': ['1', '2', '3'],
    'BCA': ['1', '2', '3'],
  };

  final Map<String, List<String>> _courseBranches = {
    'BTech': [
      'Computer Science',
      'IT',
      'ECE',
      'Mechanical',
      'Civil',
      'Chemical',
    ],
    'BSc': ['Physics', 'Chemistry', 'Mathematics', 'Biology'],
    'BBA': ['Finance', 'Marketing', 'HR'],
    'BCA': ['Computer Applications'],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCourse = null;
      _selectedBranch = null;
      _selectedYear = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Student Directory',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _sortHighToLow
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: AppTheme.accent,
                    ),
                    onPressed: () =>
                        setState(() => _sortHighToLow = !_sortHighToLow),
                    tooltip: 'Toggle Sort Order',
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  hintText: 'Search by username...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white70,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white38,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),

            // Filters Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Row(
                children: [
                  _buildDropdown<String>(
                    value: _selectedCourse,
                    hint: 'Course',
                    items: _courseYears.keys.toList(),
                    onChanged: (val) => setState(() {
                      _selectedCourse = val;
                      _selectedBranch = null;
                      _selectedYear = null;
                    }),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  _buildDropdown<String>(
                    value: _selectedYear,
                    hint: 'Year',
                    items: _selectedCourse != null
                        ? _courseYears[_selectedCourse]!
                        : [],
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  _buildDropdown<String>(
                    value: _selectedBranch,
                    hint: 'Branch',
                    items: _selectedCourse != null
                        ? _courseBranches[_selectedCourse]!
                        : [],
                    onChanged: (val) => setState(() => _selectedBranch = val),
                  ),
                  if (_selectedCourse != null ||
                      _selectedYear != null ||
                      _selectedBranch != null)
                    Padding(
                      padding: const EdgeInsets.only(left: AppTheme.spaceSm),
                      child: ActionChip(
                        label: const Text('Clear'),
                        onPressed: _resetFilters,
                        backgroundColor: AppTheme.error.withValues(alpha: 0.2),
                        labelStyle: const TextStyle(color: AppTheme.error),
                        side: BorderSide.none,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error loading students',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Local filtering
                  var filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['role'] == 'teacher')
                      return false; // Hide teachers

                    if (_selectedCourse != null &&
                        data['course'] != _selectedCourse)
                      return false;
                    if (_selectedYear != null && data['year'] != _selectedYear)
                      return false;
                    if (_selectedBranch != null &&
                        data['branch'] != _selectedBranch)
                      return false;

                    if (_searchQuery.isNotEmpty) {
                      final username =
                          data['username']?.toString().toLowerCase() ?? '';
                      if (!username.contains(_searchQuery.toLowerCase()))
                        return false;
                    }

                    return true;
                  }).toList();

                  // Sort locally
                  filtered.sort((a, b) {
                    final repA =
                        ((a.data() as Map<String, dynamic>)['reputation']
                                as num?)
                            ?.toDouble() ??
                        0.0;
                    final repB =
                        ((b.data() as Map<String, dynamic>)['reputation']
                                as num?)
                            ?.toDouble() ??
                        0.0;
                    return _sortHighToLow
                        ? repB.compareTo(repA)
                        : repA.compareTo(repB);
                  });

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No students found.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                      vertical: AppTheme.spaceSm,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final rep =
                          (data['reputation'] as num?)?.toDouble() ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spaceMd,
                        ),
                        child: GlassmorphicCard(
                          padding: const EdgeInsets.all(AppTheme.spaceMd),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.accent.withValues(
                                alpha: 0.2,
                              ),
                              child: Text(
                                data['name']
                                        ?.toString()
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    '?',
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              data['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '@${data['username'] ?? 'unknown'}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rep.toStringAsFixed(2),
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StudentProfileScreen(uid: doc.id),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          dropdownColor: AppTheme.navyMedium,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.white54,
            size: 20,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
              .toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _TeacherProfileTab
// ═══════════════════════════════════════════════════════════════════════════

class _TeacherProfileTab extends ConsumerWidget {
  const _TeacherProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.accent,
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              Text(
                user?.email?.split('@').first ?? 'Teacher',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                user?.email ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
