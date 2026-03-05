import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interaction.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ReputationState
// ═══════════════════════════════════════════════════════════════════════════

class ReputationState {
  /// Raw weighted peer score from all incoming ratings.
  final double peerScore;

  /// CGPA normalised to 0–1 (cgpa / 10).
  final double normalizedCGPA;

  /// Faculty-assigned score (0–1).
  final double teacherScore;

  /// The "raw" reputation BEFORE smoothing is applied.
  final double calculatedReputation;

  /// The final reputation score the user sees, after exponential smoothing.
  final double finalReputation;

  /// How much of [finalReputation] comes from the PREVIOUS score (0.7).
  final double smoothingAnchor;

  /// The user's credibility weight when they rate someone else.
  final double credibility;

  /// Recent interactions (ratings) targeting this user.
  final List<Interaction> recentInteractions;

  /// True while data is being fetched.
  final bool isLoading;

  const ReputationState({
    this.peerScore = 0,
    this.normalizedCGPA = 0,
    this.teacherScore = 0,
    this.calculatedReputation = 0,
    this.finalReputation = 0,
    this.smoothingAnchor = 0.7,
    this.credibility = 0,
    this.recentInteractions = const [],
    this.isLoading = false,
  });

  ReputationState copyWith({
    double? peerScore,
    double? normalizedCGPA,
    double? teacherScore,
    double? calculatedReputation,
    double? finalReputation,
    double? smoothingAnchor,
    double? credibility,
    List<Interaction>? recentInteractions,
    bool? isLoading,
  }) {
    return ReputationState(
      peerScore: peerScore ?? this.peerScore,
      normalizedCGPA: normalizedCGPA ?? this.normalizedCGPA,
      teacherScore: teacherScore ?? this.teacherScore,
      calculatedReputation: calculatedReputation ?? this.calculatedReputation,
      finalReputation: finalReputation ?? this.finalReputation,
      smoothingAnchor: smoothingAnchor ?? this.smoothingAnchor,
      credibility: credibility ?? this.credibility,
      recentInteractions: recentInteractions ?? this.recentInteractions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ReputationNotifier
// ═══════════════════════════════════════════════════════════════════════════

class ReputationNotifier extends StateNotifier<ReputationState> {
  ReputationNotifier() : super(const ReputationState());

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<QuerySnapshot>? _ratingsSub;

  /// Resets the reputation state to defaults (used on sign-out).
  void reset() {
    _userSub?.cancel();
    _ratingsSub?.cancel();
    state = const ReputationState();
  }

  /// Loads reputation data for [userId] via real-time Firestore streams.
  Future<void> loadReputation(String userId) async {
    state = state.copyWith(isLoading: true);

    _userSub?.cancel();
    _ratingsSub?.cancel();

    // 1. Listen to user document for core stats
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;
          final data = doc.data()!;

          double parseDouble(dynamic val) {
            if (val is num) return val.toDouble();
            if (val is String) return double.tryParse(val) ?? 0.0;
            return 0.0;
          }

          final normalizedCGPA = parseDouble(data['cgpa_score']) / 10.0;
          final teacherScore = parseDouble(data['teacher_score']);
          final peerScore = parseDouble(data['peer_score']);
          final finalRep = parseDouble(data['reputation']);

          // Credibility Formula
          final credibility = ((0.6 * normalizedCGPA) + (0.4 * finalRep)).clamp(
            0.0,
            1.0,
          );

          // Hybrid formula
          final calculated =
              (0.5 * peerScore) + (0.3 * normalizedCGPA) + (0.2 * teacherScore);

          state = state.copyWith(
            normalizedCGPA: normalizedCGPA,
            teacherScore: teacherScore,
            peerScore: peerScore,
            finalReputation: finalRep,
            calculatedReputation: calculated,
            credibility: credibility,
            isLoading: false,
          );
        });

    // 2. Listen to recent ratings (last 20 for this user)
    _ratingsSub = FirebaseFirestore.instance
        .collection('ratings')
        .where('toUser', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
          final interactions = snap.docs.map((doc) {
            return Interaction.fromMap(doc.id, doc.data());
          }).toList();

          state = state.copyWith(recentInteractions: interactions);
        });
  }

  // ═════════════════════════════════════════════════════════════════════
  // submitRating — PRD §9 (System Flow: Submit a Rating)
  // ═════════════════════════════════════════════════════════════════════
  Future<double> submitRating({
    required String fromUser,
    required String toUser,
    required int rating,
    String comment = '',
  }) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) throw Exception("You must be logged in to rate.");

    final realFromUid = authUser.uid;
    final realFromName = authUser.displayName ?? 'Student';

    // PRD Security: throw error if user tries to rate themselves
    if (realFromUid == toUser) {
      throw Exception("You cannot rate yourself.");
    }

    final firestore = FirebaseFirestore.instance;

    // ── 3-day cooldown check per fromUser→toUser pair ─────────────────
    final lastRatingSnap = await firestore
        .collection('ratings')
        .where('fromUser', isEqualTo: realFromUid)
        .where('toUser', isEqualTo: toUser)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastRatingSnap.docs.isNotEmpty) {
      final lastDoc = lastRatingSnap.docs.first.data();
      final lastTimestamp = lastDoc['timestamp'];
      if (lastTimestamp != null) {
        final lastDate = (lastTimestamp as dynamic).toDate() as DateTime;
        final daysSince = DateTime.now().difference(lastDate).inDays;
        if (daysSince < 3) {
          // Fetch target user name for the error message
          final targetDoc = await firestore
              .collection('users')
              .doc(toUser)
              .get();
          final targetName =
              (targetDoc.data()?['name'] as String?) ?? 'this user';
          final daysLeft = 3 - daysSince;
          throw Exception(
            'You already rated $targetName recently. You can rate them again in $daysLeft days',
          );
        }
      }
    }

    final targetUserRef = firestore.collection('users').doc(toUser);
    final raterUserRef = firestore.collection('users').doc(realFromUid);
    final ratingDocRef = firestore.collection('ratings').doc();

    final appliedCredibility = await firestore.runTransaction((tx) async {
      final targetDoc = await tx.get(targetUserRef);
      if (!targetDoc.exists) throw Exception("Target user not found.");

      // Fetch rater's display name and credibility from their Firestore user document
      final raterDoc = await tx.get(raterUserRef);
      final raterData = raterDoc.data() ?? {};
      final raterName = (raterData['name'] as String?)?.isNotEmpty == true
          ? raterData['name'] as String
          : (realFromName.isNotEmpty ? realFromName : 'Student');
      final raterCredibility =
          (raterData['credibility'] as num?)?.toDouble() ?? 0.1;

      final d = targetDoc.data()!;
      final oldRep = (d['reputation'] as num?)?.toDouble() ?? 0.0;

      // Credibility-weighted rating
      final ratingValue0to1 = rating / 5.0;
      final weightedRating = ratingValue0to1 * raterCredibility;

      // 1. Write the rating document
      tx.set(ratingDocRef, {
        'fromUser': realFromUid,
        'toUser': toUser,
        'toId': toUser,
        'rating': rating,
        'ratingValue': ratingValue0to1,
        'weightedRating': weightedRating,
        'raterCredibility': raterCredibility,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
        'fromUserName': raterName,
        'fromName': raterName,
      });

      // 2. Update target user stats
      final newRep = oldRep == 0
          ? weightedRating
          : (oldRep * 0.7) + (weightedRating * 0.3);

      tx.update(targetUserRef, {
        'totalRatingsReceived': FieldValue.increment(1),
        'reputation': newRep,
      });

      // 3. Update rater stats
      tx.update(raterUserRef, {'totalRatingsGiven': FieldValue.increment(1)});

      return raterCredibility;
    });

    // 4. After transaction: recalculate peer score average from all ratings
    await _recalculatePeerScore(toUser);

    return appliedCredibility;
  }

  /// Calculates the average of ALL ratings for [userId] and updates
  /// `peer_score` and `reputation` (total score) on their user document.
  Future<void> _recalculatePeerScore(String userId) async {
    final firestore = FirebaseFirestore.instance;

    final ratingsSnap = await firestore
        .collection('ratings')
        .where('toUser', isEqualTo: userId)
        .get();

    if (ratingsSnap.docs.isEmpty) return;

    // Use weightedRating if available, fall back to raw rating / 5.0
    final allWeighted = ratingsSnap.docs.map((doc) {
      final data = doc.data();
      if (data.containsKey('weightedRating')) {
        return (data['weightedRating'] as num?)?.toDouble() ?? 0.0;
      }
      return ((data['rating'] as num?)?.toDouble() ?? 0.0) / 5.0;
    }).toList();

    final average = allWeighted.reduce((a, b) => a + b) / allWeighted.length;

    // weightedRating is already 0–1 scale
    final peerScore = average.clamp(0.0, 1.0);

    // Fetch user doc to get cgpa_score and teacher_score for total calculation
    final userDoc = await firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final normalizedCGPA = parseDouble(userData['cgpa_score']) / 10.0;
    final teacherScore = parseDouble(userData['teacher_score']);

    // Total Score: (peer_score * 0.5) + (cgpa_score * 0.3) + (teacher_score * 0.2)
    final totalReputation =
        (peerScore * 0.5) + (normalizedCGPA * 0.3) + (teacherScore * 0.2);

    // Credibility: 0.6×cgpa + 0.4×totalRep
    final credibility = ((0.6 * normalizedCGPA) + (0.4 * totalReputation))
        .clamp(0.0, 1.0);

    await firestore.collection('users').doc(userId).update({
      'peer_score': peerScore,
      'reputation': totalReputation,
      'credibility': credibility,
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _ratingsSub?.cancel();
    super.dispose();
  }
}

/// ── Global provider ────────────────────────────────────────────────────────
final reputationProvider =
    StateNotifierProvider<ReputationNotifier, ReputationState>(
      (ref) => ReputationNotifier(),
    );
