import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StudentProfileScreen extends StatelessWidget {
  final String uid;

  const StudentProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy, AppTheme.navyMedium],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                );
              }

              if (snap.hasError || !snap.hasData || !(snap.data!.exists)) {
                return const Center(
                  child: Text(
                    'User not found',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final data = snap.data!.data() as Map<String, dynamic>;

              double parseDouble(dynamic val) {
                if (val is num) return val.toDouble();
                if (val is String) return double.tryParse(val) ?? 0.0;
                return 0.0;
              }

              final name = (data['name'] as String?) ?? 'Student';
              final username = (data['username'] as String?) ?? '';
              final cgpa = parseDouble(data['cgpa_score']);
              final peerScore = parseDouble(data['peer_score']);
              final teacherScore = parseDouble(data['teacher_score']);

              final normalizedCGPA = cgpa / 10.0;
              final totalScore =
                  (peerScore * 0.5) +
                  (normalizedCGPA * 0.3) +
                  (teacherScore * 0.2);

              final bio = data['bio']?.toString().trim() ?? '';
              final branch = data['branch']?.toString().trim() ?? '';
              final course = data['course']?.toString().trim() ?? '';
              final year = data['year']?.toString().trim() ?? '';
              final skillsList = data['skills'] as List<dynamic>? ?? [];
              final skills = skillsList.map((e) => e.toString()).toList();

              final displayBio = bio.isEmpty ? 'Not specified' : bio;
              final displayBranch = branch.isEmpty ? 'Not specified' : branch;
              final displayCourse = course.isEmpty ? 'Not specified' : course;
              final displayYear = year.isEmpty ? 'Not specified' : year;

              final theme = Theme.of(context);
              final repColor = AppTheme.reputationColor(totalScore);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Hero(
                      tag: 'avatar_$uid',
                      child: Container(
                        width: 96,
                        height: 96,
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
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                    if (course.isNotEmpty ||
                        branch.isNotEmpty ||
                        year.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          displayCourse,
                          displayBranch,
                          if (displayYear != 'Not specified')
                            'Year $displayYear'
                          else
                            displayYear,
                        ].join(' • '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spaceLg),

                    // Reputation Card
                    Card(
                      color: AppTheme.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceLg),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CustomPaint(
                                painter: _GaugePainter(
                                  value: totalScore,
                                  color: repColor,
                                ),
                                child: Center(
                                  child: Text(
                                    totalScore.toStringAsFixed(2),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: repColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceLg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall Reputation',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: repColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm,
                                      ),
                                    ),
                                    child: Text(
                                      _tierLabel(totalScore),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: repColor,
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
                    ),

                    const SizedBox(height: AppTheme.spaceLg),

                    // Bio
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        displayBio,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: bio.isEmpty ? Colors.white38 : Colors.white70,
                          fontStyle: bio.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),

                    // Skills
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Skills',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (skills.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No skills added',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white38,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills
                              .map(
                                (skill) => Chip(
                                  label: Text(
                                    skill.trim(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: AppTheme.accent.withValues(
                                    alpha: 0.2,
                                  ),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: AppTheme.spaceLg),
                  ],
                ),
              );
            },
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

  String _tierLabel(double s) {
    if (s >= 0.75) return 'High Standing';
    if (s >= 0.40) return 'Moderate';
    return 'Needs Improvement';
  }
}

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

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

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
