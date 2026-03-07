import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the current user's profile data.
class UserProfile {
  final String userId;
  final String name;
  final double cgpa;
  final double peerScore;
  final double teacherScore;
  final int totalRatingsReceived;
  final int totalRatingsGiven;
  final DateTime? memberSince;
  final bool isLoading;
  final String bio;
  final String branch;
  final String course;
  final String year;
  final List<String> skills;

  const UserProfile({
    this.userId = '',
    this.name = '',
    this.cgpa = 0,
    this.peerScore = 0,
    this.teacherScore = 0,
    this.totalRatingsReceived = 0,
    this.totalRatingsGiven = 0,
    this.memberSince,
    this.isLoading = false,
    this.bio = '',
    this.branch = '',
    this.course = '',
    this.year = '',
    this.skills = const [],
  });

  UserProfile copyWith({
    String? userId,
    String? name,
    double? cgpa,
    double? peerScore,
    double? teacherScore,
    int? totalRatingsReceived,
    int? totalRatingsGiven,
    DateTime? memberSince,
    bool? isLoading,
    String? bio,
    String? branch,
    String? course,
    String? year,
    List<String>? skills,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      cgpa: cgpa ?? this.cgpa,
      peerScore: peerScore ?? this.peerScore,
      teacherScore: teacherScore ?? this.teacherScore,
      totalRatingsReceived: totalRatingsReceived ?? this.totalRatingsReceived,
      totalRatingsGiven: totalRatingsGiven ?? this.totalRatingsGiven,
      memberSince: memberSince ?? this.memberSince,
      isLoading: isLoading ?? this.isLoading,
      bio: bio ?? this.bio,
      branch: branch ?? this.branch,
      course: course ?? this.course,
      year: year ?? this.year,
      skills: skills ?? this.skills,
    );
  }

  /// CGPA normalised to 0–1 scale (PRD: cgpa / 10).
  double get normalizedCGPA => cgpa / 10;
}

class UserNotifier extends StateNotifier<UserProfile> {
  UserNotifier() : super(const UserProfile());

  StreamSubscription<DocumentSnapshot>? _sub;

  /// Loads user profile from Firestore in real-time.
  ///
  /// [userId] — the uid from AuthService.
  /// [displayName] — the display name from the auth provider, used
  ///   as a fallback if the Firestore document doesn't have a name yet.
  Future<void> loadUser(String userId, {String displayName = ''}) async {
    state = state.copyWith(isLoading: true);

    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            final data = doc.data()!;

            double parseDouble(dynamic val) {
              if (val is num) return val.toDouble();
              if (val is String) return double.tryParse(val) ?? 0.0;
              return 0.0;
            }

            state = state.copyWith(
              userId: userId,
              name: data['name'] ?? displayName,
              cgpa: parseDouble(data['cgpa_score']),
              peerScore: parseDouble(data['peer_score']),
              teacherScore: parseDouble(data['teacher_score']),
              totalRatingsReceived: data['totalRatingsReceived'] ?? 0,
              totalRatingsGiven: data['totalRatingsGiven'] ?? 0,
              memberSince:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              isLoading: false,
              bio: data['bio'] ?? '',
              branch: data['branch'] ?? '',
              course: data['course'] ?? '',
              year: data['year'] ?? '',
              skills: List<String>.from(data['skills'] ?? []),
            );
          } else {
            // Fallback if doc is initializing
            final name = displayName.isNotEmpty
                ? displayName
                      .split(RegExp(r'[._\-]'))
                      .map(
                        (w) => w.isNotEmpty
                            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
                            : '',
                      )
                      .join(' ')
                : 'Student';

            state = state.copyWith(
              userId: userId,
              name: name,
              cgpa: 0.0,
              isLoading: false,
            );
          }
        });
  }

  /// Updates the user profile in Firestore
  Future<void> updateProfile({
    String? bio,
    String? branch,
    String? course,
    String? year,
    List<String>? skills,
  }) async {
    if (state.userId.isEmpty) return;

    final updates = <String, dynamic>{};
    if (bio != null) updates['bio'] = bio;
    if (branch != null) updates['branch'] = branch;
    if (course != null) updates['course'] = course;
    if (year != null) updates['year'] = year;
    if (skills != null) updates['skills'] = skills;

    if (updates.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(state.userId)
          .update(updates);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Resets the user profile to defaults (used on sign-out).
  void reset() {
    _sub?.cancel();
    state = const UserProfile();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Global provider for user profile.
final userProvider = StateNotifierProvider<UserNotifier, UserProfile>(
  (ref) => UserNotifier(),
);
