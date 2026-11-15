import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/reputation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';

void showRatingSheet(
  BuildContext context, {
  String? preselectedName,
  String? preselectedUid,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _RatingSheetContent(
      preselectedName: preselectedName,
      preselectedUid: preselectedUid,
    ),
  );
}

class _StudentEntry {
  final String uid;
  final String name;
  final double cgpa;

  const _StudentEntry(this.uid, this.name, this.cgpa);
}

class _RatingSheetContent extends ConsumerStatefulWidget {
  const _RatingSheetContent({this.preselectedName, this.preselectedUid});

  final String? preselectedName;
  final String? preselectedUid;

  @override
  ConsumerState<_RatingSheetContent> createState() =>
      _RatingSheetContentState();
}

class _RatingSheetContentState extends ConsumerState<_RatingSheetContent> {

  final _searchController = TextEditingController();
  final _commentController = TextEditingController();
  String _searchQuery = '';
  _StudentEntry? _selectedStudent;
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.preselectedName != null && widget.preselectedUid != null) {
      _selectedStudent = _StudentEntry(
        widget.preselectedUid!,
        widget.preselectedName!,
        0,
      );
    }
  }

  bool get _isDuplicateRating {
    if (_selectedStudent == null) return false;
    final interactions = ref.read(reputationProvider).recentInteractions;
    final currentUser = ref.read(authServiceProvider).currentUser;
    final currentUid = currentUser?.uid ?? 'current_user';

    return interactions.any(
      (i) => i.fromUser == currentUid && i.toUser == _selectedStudent!.uid,
    );
  }

  bool get _canSubmit =>
      _selectedStudent != null &&
      _rating > 0 &&
      !_isDuplicateRating &&
      !_isSubmitting;

  String? get _guardMessage {
    if (_isDuplicateRating) {
      return 'You have already rated ${_selectedStudent!.name}.';
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(authServiceProvider).currentUser;
      final fromUid = currentUser?.uid ?? 'current_user';

      final appliedCredibility = await ref
          .read(reputationProvider.notifier)
          .submitRating(
            fromUser: fromUid,
            toUser: _selectedStudent!.uid,
            rating: _rating,
            comment: _commentController.text.trim(),
          );

      await HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rating Applied. Your influence weight of '
              '${appliedCredibility.toStringAsFixed(2)} was used to '
              'calculate this impact.',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final currentUid = currentUser?.uid ?? '';

    return Container(

      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),

      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        color: AppTheme.navy.withValues(alpha: 0.85),
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
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              AppTheme.spaceMd,
              AppTheme.spaceLg,
              MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                Text(
                  'Rate a Student',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PRD §9 — Peer rating (1–5)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    hintText: 'Search student by name...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
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
                              size: 20,
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
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),

                if (_selectedStudent == null) ...[
                  SizedBox(
                    height: 180,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('name')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accent,
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final filtered = docs.where((doc) {
                          if (doc.id == currentUid) return false;
                          if (_searchQuery.isEmpty) return true;
                          final name =
                              (doc.data() as Map<String, dynamic>)['name'] ??
                              '';
                          return name.toString().toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No students available'
                                  : 'No results for "$_searchQuery"',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final doc = filtered[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final student = _StudentEntry(
                              doc.id,
                              (data['name'] ?? 'Unknown').toString(),
                              (data['cgpa_score'] as num?)?.toDouble() ?? 0.0,
                            );
                            return _StudentSelectTile(
                              student: student,
                              onTap: () {
                                setState(() => _selectedStudent = student);
                                HapticFeedback.selectionClick();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[

                  GlassmorphicCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                      vertical: 12,
                    ),
                    fillOpacity: 0.10,
                    margin: EdgeInsets.zero,
                    child: Row(
                      children: [

                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text(
                              _initials(_selectedStudent!.name),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedStudent!.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'CGPA ${_selectedStudent!.cgpa.toStringAsFixed(1)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                          onPressed: () => setState(() {
                            _selectedStudent = null;
                            _rating = 0;
                            _commentController.clear();
                          }),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spaceMd),

                if (_selectedStudent != null) ...[
                  Text(
                    'Peer Score',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _rating = starIndex);
                          HapticFeedback.selectionClick();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedScale(
                            scale: starIndex <= _rating ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              starIndex <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: starIndex <= _rating
                                  ? AppTheme.warning
                                  : Colors.white24,
                              size: 40,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$_rating / 5',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceMd),

                  TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      hintText: 'Add a comment (optional)...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.comment_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),

                  if (_guardMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _guardMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.warning,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.accent.withValues(
                          alpha: 0.3,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isDuplicateRating
                                  ? 'Already Rated'
                                  : 'Submit Rating',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spaceSm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}

class _StudentSelectTile extends StatelessWidget {
  const _StudentSelectTile({required this.student, required this.onTap});

  final _StudentEntry student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: 12,
        ),
        fillOpacity: 0.06,
        borderOpacity: 0.10,
        margin: EdgeInsets.zero,
        child: Row(
          children: [

            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.12),
              ),
              child: Center(
                child: Text(
                  _initials(student.name),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'CGPA ${student.cgpa.toStringAsFixed(1)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
