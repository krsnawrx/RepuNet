import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/report_provider.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ReportStudentSheet — Senior UI/UX Architecture
// ═══════════════════════════════════════════════════════════════════════════
//
// Features:
//   1. Dark Glassmorphism via BackdropFilter.
//   2. High-legibility Reason Chips (Black text on light background).
//   3. Managed Firestore integration via Riverpod.
//   4. Haptic feedback on interactions.
// ═══════════════════════════════════════════════════════════════════════════

class ReportStudentSheet extends ConsumerStatefulWidget {
  final String reportedUid;
  final String reportedName;

  const ReportStudentSheet({
    super.key,
    required this.reportedUid,
    required this.reportedName,
  });

  @override
  ConsumerState<ReportStudentSheet> createState() => _ReportStudentSheetState();
}

class _ReportStudentSheetState extends ConsumerState<ReportStudentSheet> {
  static const _reasons = [
    'Spam',
    'Harassment',
    'Fake Score',
    'Inappropriate Bio',
  ];

  String? _selectedReason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportState = ref.watch(reportProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Listen for success state to close and signal feedback
    ref.listen(reportProvider, (previous, next) {
      if (next.status == ReportStatus.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Report submitted to MUJ Administration'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
        ref.read(reportProvider.notifier).reset();
      } else if (next.status == ReportStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Submission failed'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppTheme.navy.withValues(alpha: 0.88),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceLg,
              vertical: AppTheme.spaceMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag Handle ──────────────────────────────────────
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // ── 1. Circular Flag Icon (Blurred Purple Circle) ─────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.deepPurple.withValues(alpha: 0.25),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // ── 2. Typography ────────────────────────────────────
                Text(
                  'Report Student',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a reason for documenting this student',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // ── 3. The Fix: Legible Reason Chips ──────────────────
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _reasons.map((reason) {
                    final isSelected = _selectedReason == reason;
                    return ChoiceChip(
                      label: Text(reason),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedReason = reason);
                        }
                      },
                      // STYLE: Unselected = Light/White, Text = Black
                      //        Selected = Purple/Accent
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      selectedColor: Colors.deepPurpleAccent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.deepPurpleAccent
                            : Colors.transparent,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // ── 4. Text Field ────────────────────────────────────
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  minLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  cursorColor: AppTheme.accent,
                  decoration: InputDecoration(
                    hintText: 'Optional details...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // ── 5. Submit Button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_selectedReason == null ||
                            reportState.status == ReportStatus.loading)
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            ref.read(reportProvider.notifier).submitReport(
                                  reportedId: widget.reportedUid,
                                  reason: _selectedReason!,
                                  details: _detailsController.text,
                                );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      disabledBackgroundColor: AppTheme.error.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 0,
                    ),
                    child: reportState.status == ReportStatus.loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Submit Report',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper: Show Function
// ═══════════════════════════════════════════════════════════════════════════

void showReportStudentSheet(
  BuildContext context, {
  required String reportedUid,
  required String reportedName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReportStudentSheet(
      reportedUid: reportedUid,
      reportedName: reportedName,
    ),
  );
}
