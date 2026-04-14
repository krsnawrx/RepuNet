import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/reputation_provider.dart';
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
    _TeacherReportsTab(),
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
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag_rounded),
            label: 'Reports',
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
                            onTap: () => _showStudentActionSheet(
                              context,
                              doc.id,
                              data['name']?.toString() ?? 'Unknown',
                              (data['cgpa_score'] as num?)?.toDouble() ?? 0.0,
                            ),
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

  /// Shows an action sheet with 'Rate Student' and 'Update CGPA' options.
  void _showStudentActionSheet(
    BuildContext context,
    String studentUid,
    String studentName,
    double currentCgpa,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              studentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentProfileScreen(uid: studentUid),
                    ),
                  );
                },
                icon: const Icon(Icons.star_rounded, color: Colors.white),
                label: const Text(
                  'Rate Student',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showUpdateCgpaSheet(
                    context,
                    studentUid,
                    studentName,
                    currentCgpa,
                  );
                },
                icon: const Icon(Icons.school_rounded, color: Colors.white),
                label: const Text(
                  'Update CGPA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
  }

  /// Shows a bottom sheet for updating a student's CGPA.
  void _showUpdateCgpaSheet(
    BuildContext context,
    String studentUid,
    String studentName,
    double currentCgpa,
  ) {
    final cgpaController = TextEditingController(
      text: currentCgpa > 0 ? currentCgpa.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            margin: EdgeInsets.only(bottom: bottomInset),
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: AppTheme.navy,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Update CGPA — $studentName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current CGPA: ${currentCgpa.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: cgpaController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 0.0 || parsed > 10.0) {
                        return 'CGPA must be between 0.0 and 10.0';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'New CGPA (0.0 – 10.0)',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.error,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.error,
                          width: 2,
                        ),
                      ),
                      errorStyle: const TextStyle(color: AppTheme.error),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    final parsed = double.parse(
                                      cgpaController.text.trim(),
                                    );

                                    setState(() => isSaving = true);

                                    try {
                                      final firestore =
                                          FirebaseFirestore.instance;
                                      final userDoc = await firestore
                                          .collection('users')
                                          .doc(studentUid)
                                          .get();
                                      final userData = userDoc.data() ?? {};
                                      final reputation =
                                          (userData['reputation'] as num?)
                                                  ?.toDouble() ??
                                              0.0;

                                      final normalizedCgpa = parsed / 10.0;
                                      final credibility = ((0.6 *
                                                  normalizedCgpa) +
                                              (0.4 * reputation))
                                          .clamp(0.0, 1.0);

                                      await firestore
                                          .collection('users')
                                          .doc(studentUid)
                                          .update({
                                            'cgpa_score': parsed,
                                            'credibility': credibility,
                                          });

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'CGPA updated successfully',
                                            ),
                                            backgroundColor: AppTheme.success,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e
                                                  .toString()
                                                  .replaceAll(
                                                    'Exception: ',
                                                    '',
                                                  ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: AppTheme.error,
                                          ),
                                        );
                                      }
                                      setState(() => isSaving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _TeacherReportsTab — Pending Reports Moderation
// ═══════════════════════════════════════════════════════════════════════════

class _TeacherReportsTab extends StatelessWidget {
  const _TeacherReportsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.warning.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppTheme.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Reports',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Review student misconduct reports',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),

            // ── Reports Stream ──────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .where('status', isEqualTo: 'pending')
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.error,
                            size: 40,
                          ),
                          const SizedBox(height: AppTheme.spaceMd),
                          Text(
                            'Error loading reports. Check connection or indices.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  
                  // Sort locally to avoid needing a Firestore composite index
                  // for 'status' == 'pending' and 'timestamp' DESC.
                  final List<Report> reports = docs.map((d) {
                    return Report.fromMap(d.id, d.data() as Map<String, dynamic>);
                  }).toList()
                    ..sort((a, b) {
                      final timeA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final timeB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return timeB.compareTo(timeA); // Descending
                    });

                  // ── Empty State ────────────────────────────────────
                  if (reports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.success.withValues(alpha: 0.12),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppTheme.success,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceLg),
                          Text(
                            'All clear!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No pending reports to review',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ── Reports List ──────────────────────────────────
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                    ).copyWith(bottom: 100),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return _ReportCard(report: reports[index]);
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
}

// ═══════════════════════════════════════════════════════════════════════════
// _ReportCard — Individual report card with actions
// ═══════════════════════════════════════════════════════════════════════════

class _ReportCard extends ConsumerWidget {
  const _ReportCard({
    required this.report,
  });

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      fillOpacity: 0.10,
      borderOpacity: 0.14,
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Reason badge + Timestamp ─────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _reasonIcon(report.reason),
                      color: AppTheme.warning,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      report.reason,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (report.timestamp != null)
                Text(
                  _timeAgo(report.timestamp!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white30,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // ── Live Users Info Fetching ────────────────────────────────
          // We fetch both the reporter and reported student to show Handles
          FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance.collection('users').doc(report.reporterId).get(),
              FirebaseFirestore.instance.collection('users').doc(report.reportedId).get(),
            ]),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting || !snap.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Loading participants...",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white30),
                  ),
                );
              }

              final reporterDoc = snap.data![0];
              final reportedDoc = snap.data![1];

              final reporterHandle = reporterDoc.exists
                  ? '@${(reporterDoc.data() as Map<String, dynamic>)['username'] ?? 'unknown'}'
                  : '@unknown';
              
              final reportedName = reportedDoc.exists
                  ? (reportedDoc.data() as Map<String, dynamic>)['name']?.toString() ?? 'Unknown'
                  : 'Unknown';
              final reportedHandle = reportedDoc.exists
                  ? '@${(reportedDoc.data() as Map<String, dynamic>)['username'] ?? 'unknown'}'
                  : '@unknown';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text: @reporter flagged @reported
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60, fontSize: 13),
                      children: [
                        TextSpan(
                          text: reporterHandle, 
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accentLight)
                        ),
                        const TextSpan(text: ' flagged '),
                        TextSpan(
                          text: reportedHandle, 
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error)
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  // Reported Student Avatar & Name
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.error.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Text(
                            reportedName.isNotEmpty ? reportedName[0].toUpperCase() : '?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reportedName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (reportedHandle.isNotEmpty)
                            Text(
                              reportedHandle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: Text(
                          'REPORTED',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.error,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          // ── Details (if any) ─────────────────────────────────────
          if (report.details.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                report.details,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spaceMd),

          // ── Action Buttons: Dismiss + Validate & Penalize ────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDismiss(context, report.id),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSm,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPenaltyConfirmation(
                      context,
                      ref,
                      report,
                    ),
                    icon: const Icon(
                      Icons.gavel_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Validate & Penalize',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppTheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSm,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dismiss: mark report as resolved ────────────────────────────────
  Future<void> _handleDismiss(BuildContext context, String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': 'resolved_dismissed'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white54, size: 20),
                SizedBox(width: 8),
                Text('Report dismissed & ignored.'),
              ],
            ),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ── Penalty Confirmation Dialog ─────────────────────────────────────
  void _showPenaltyConfirmation(
    BuildContext context,
    WidgetRef ref,
    Report report,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navyLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.error.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Penalty',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validate this report? This will deduct exactly 0.1 from the reported student\'s reputation.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reason: ${report.reason}',
                    style: const TextStyle(
                      color: AppTheme.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executePenalty(context, ref, report);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            child: const Text(
              'Apply 0.1 Penalty',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Execute Penalty: Atomic Service Call ──────────────────────────
  Future<void> _executePenalty(
    BuildContext context,
    WidgetRef ref,
    Report report,
  ) async {
    try {
      await ref.read(reputationProvider.notifier).penalizeStudent(
        studentId: report.reportedId,
        reportId: report.id,
        penaltyAmount: 0.1,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.gavel_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Penalty applied — reputation deducted by 0.1'),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error applying penalty: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  IconData _reasonIcon(String reason) {
    switch (reason.toLowerCase()) {
      case 'spam':
        return Icons.block_rounded;
      case 'harassment':
        return Icons.warning_amber_rounded;
      case 'fake score':
        return Icons.score_rounded;
      case 'inappropriate bio':
        return Icons.edit_off_rounded;
      default:
        return Icons.flag_rounded;
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
