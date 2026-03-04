import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/reputation_provider.dart';
import '../theme/app_theme.dart';

/// Profile tab — user info, reputation breakdown pie chart, and details.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final uid = authAsync.valueOrNull?.uid;
    final theme = Theme.of(context);

    if (uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        // Helper to parse numbers robustly
        double parseDouble(dynamic val) {
          if (val is num) return val.toDouble();
          if (val is String) return double.tryParse(val) ?? 0.0;
          return 0.0;
        }

        final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};

        final name = (data['name'] as String?) ?? 'Student';
        final cgpa = parseDouble(data['cgpa_score']);
        final peerScore = parseDouble(data['peer_score']);
        final teacherScore = parseDouble(data['teacher_score']);
        final totalReceived = (data['totalRatingsReceived'] as int?) ?? 0;
        final totalGiven = (data['totalRatingsGiven'] as int?) ?? 0;
        final memberSince = (data['createdAt'] as Timestamp?)?.toDate();

        final normalizedCGPA = cgpa / 10.0;

        // Total Score formula requested:
        // (peer_score * 0.5) + (cgpa_score * 0.3) + (teacher_score * 0.2)
        final totalScore =
            (peerScore * 0.5) + (normalizedCGPA * 0.3) + (teacherScore * 0.2);

        final credibility = ((0.6 * normalizedCGPA) + (0.4 * totalScore)).clamp(
          0.0,
          1.0,
        );

        final rep = ReputationState(
          peerScore: peerScore,
          normalizedCGPA: normalizedCGPA,
          teacherScore: teacherScore,
          calculatedReputation: totalScore,
          finalReputation: totalScore,
          credibility: credibility,
        );

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Profile Header ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.navy, AppTheme.navyLight],
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: AppTheme.spaceLg),
                            // Avatar
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accent.withValues(alpha: 0.2),
                                border: Border.all(
                                  color: AppTheme.accent,
                                  width: 2.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _initials(name),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            Text(
                              name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'CGPA ${cgpa.toStringAsFixed(1)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                title: const Text('Profile'),
              ),

              // ── Body ────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(AppTheme.spaceMd).copyWith(
                  bottom: 100, // extra padding to clear the BottomAppBar
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Reputation Score ──────────────────────────────────
                    _ScoreCard(reputation: totalScore),
                    const SizedBox(height: AppTheme.spaceMd),

                    // ── Pie Chart ─────────────────────────────────────────
                    Text(
                      'Reputation Breakdown',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    _ReputationPieChart(rep: rep),
                    const SizedBox(height: AppTheme.spaceMd),

                    // ── Score Details (Collapsible ExpansionTile) ────────
                    Card(
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(
                          Icons.analytics_rounded,
                          color: AppTheme.accent,
                        ),
                        title: Text(
                          'Score Details',
                          style: theme.textTheme.titleMedium,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceMd,
                            ).copyWith(bottom: AppTheme.spaceMd),
                            child: Column(
                              children: [
                                _DetailRow(
                                  label: 'Peer Score',
                                  raw: rep.peerScore,
                                  weight: 0.5,
                                  color: AppTheme.accent,
                                ),
                                _DetailRow(
                                  label: 'Normalised CGPA',
                                  raw: rep.normalizedCGPA,
                                  weight: 0.3,
                                  color: AppTheme.navyMedium,
                                ),
                                _DetailRow(
                                  label: 'Teacher Score',
                                  raw: rep.teacherScore,
                                  weight: 0.2,
                                  color: AppTheme.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSm),

                    // ── Credibility & Protections (Collapsible) ───────────
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.shield_rounded,
                          color: AppTheme.success,
                        ),
                        title: Text(
                          'Credibility & Protections',
                          style: theme.textTheme.titleMedium,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceMd,
                            ).copyWith(bottom: AppTheme.spaceMd),
                            child: Column(
                              children: [
                                _KeyValue(
                                  label: 'Your Credibility Weight',
                                  value: rep.credibility.toStringAsFixed(3),
                                  icon: Icons.shield_rounded,
                                  color: AppTheme.accent,
                                ),
                                Divider(
                                  color: AppTheme.navy.withValues(alpha: 0.06),
                                ),
                                _KeyValue(
                                  label: 'Smoothing Factor',
                                  value: '70 / 30 EMA',
                                  icon: Icons.tune_rounded,
                                  color: AppTheme.navyMedium,
                                ),
                                Divider(
                                  color: AppTheme.navy.withValues(alpha: 0.06),
                                ),
                                _KeyValue(
                                  label: 'Influence Cap',
                                  value: 'Active',
                                  icon: Icons.security_rounded,
                                  color: AppTheme.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceMd),

                    // ── Account Info ──────────────────────────────────────
                    Text('Account', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppTheme.spaceSm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          children: [
                            _KeyValue(
                              label: 'Ratings Received',
                              value: '$totalReceived',
                              icon: Icons.arrow_downward_rounded,
                              color: AppTheme.success,
                            ),
                            Divider(
                              color: AppTheme.navy.withValues(alpha: 0.06),
                            ),
                            _KeyValue(
                              label: 'Ratings Given',
                              value: '$totalGiven',
                              icon: Icons.arrow_upward_rounded,
                              color: AppTheme.accent,
                            ),
                            Divider(
                              color: AppTheme.navy.withValues(alpha: 0.06),
                            ),
                            _KeyValue(
                              label: 'Member Since',
                              value: _formatDate(memberSince),
                              icon: Icons.calendar_today_rounded,
                              color: AppTheme.navyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),

                    // ── Logout Button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _showSignOutDialog(context, ref),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: BorderSide(
                            color: AppTheme.error.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXl),
                  ]),
                ),
              ),
            ],
          ),
        );
      }, // closes StreamBuilder builder
    ); // closes StreamBuilder
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.navy.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.error.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Title
              const Text(
                'Sign Out?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),

              // Content
              Text(
                'Are you sure you want to log out of RepuNet?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // Actions
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),

                  // Sign Out
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(reputationProvider.notifier).reset();
                        ref.read(authServiceProvider).signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
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

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ── Score card at top of profile ────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.reputation});
  final double reputation;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.reputationColor(reputation);
    return Card(
      color: AppTheme.navy,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Row(
          children: [
            // Circular gauge
            SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                painter: _GaugePainter(value: reputation, color: color),
                child: Center(
                  child: Text(
                    reputation.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Reputation',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      _tierLabel(reputation),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tierLabel(double s) {
    if (s >= 0.75) return 'High Standing';
    if (s >= 0.40) return 'Moderate';
    return 'Needs Improvement';
  }
}

// ── Circular gauge painter ──────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * value.clamp(0.0, 1.0);

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Value arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ── Pie chart showing the 0.5 / 0.3 / 0.2 weight distribution ──────────────

class _ReputationPieChart extends StatefulWidget {
  const _ReputationPieChart({required this.rep});
  final ReputationState rep;

  @override
  State<_ReputationPieChart> createState() => _ReputationPieChartState();
}

class _ReputationPieChartState extends State<_ReputationPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final rep = widget.rep;
    final theme = Theme.of(context);

    // Weighted contributions (for pie sizing)
    final peerContrib = rep.peerScore * 0.5;
    final cgpaContrib = rep.normalizedCGPA * 0.3;
    final teacherContrib = rep.teacherScore * 0.2;
    final total = peerContrib + cgpaContrib + teacherContrib;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 42,
                  sections: [
                    _section(
                      index: 0,
                      title: 'Peer\n50%',
                      value: total > 0 ? (peerContrib / total) * 100 : 50,
                      color: AppTheme.accent,
                    ),
                    _section(
                      index: 1,
                      title: 'CGPA\n30%',
                      value: total > 0 ? (cgpaContrib / total) * 100 : 30,
                      color: AppTheme.navyMedium,
                    ),
                    _section(
                      index: 2,
                      title: 'Teacher\n20%',
                      value: total > 0 ? (teacherContrib / total) * 100 : 20,
                      color: AppTheme.success,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),

            // Legend
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: AppTheme.spaceMd,
              runSpacing: AppTheme.spaceSm,
              children: [
                _LegendDot(
                  color: AppTheme.accent,
                  label: 'Peer (50%)',
                  value: peerContrib,
                ),
                _LegendDot(
                  color: AppTheme.navyMedium,
                  label: 'CGPA (30%)',
                  value: cgpaContrib,
                ),
                _LegendDot(
                  color: AppTheme.success,
                  label: 'Teacher (20%)',
                  value: teacherContrib,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Total: ${total.toStringAsFixed(3)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section({
    required int index,
    required String title,
    required double value,
    required Color color,
  }) {
    final isTouched = index == _touchedIndex;
    final radius = isTouched ? 60.0 : 50.0;
    final fontSize = isTouched ? 14.0 : 12.0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: title,
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.3,
      ),
      titlePositionPercentageOffset: 0.55,
    );
  }
}

// ── Legend dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(3),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Detail row (raw score × weight = contribution) ─────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.raw,
    required this.weight,
    required this.color,
  });
  final String label;
  final double raw;
  final double weight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final contribution = raw * weight;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${raw.toStringAsFixed(2)} × ${(weight * 100).toInt()}%'
                    ' = ${contribution.toStringAsFixed(3)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              contribution.toStringAsFixed(3),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Key-value row ──────────────────────────────────────────────────────────

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
