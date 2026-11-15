import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/interaction.dart';

class ReputationState {

  final double peerScore;

  final double normalizedCGPA;

  final double teacherScore;

  final double calculatedReputation;

  final double finalReputation;

  final double smoothingAnchor;

  final double credibility;

  final List<Interaction> recentInteractions;

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

class ReputationNotifier extends StateNotifier<ReputationState> {
  ReputationNotifier() : super(const ReputationState());

  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<QuerySnapshot>? _ratingsSub;

  void reset() {
    _userSub?.cancel();
    _ratingsSub?.cancel();
    state = const ReputationState();
  }

  Future<void> loadReputation(String userId) async {
    state = state.copyWith(isLoading: true);

    _userSub?.cancel();
    _ratingsSub?.cancel();

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

          final credibility = ((0.6 * normalizedCGPA) + (0.4 * finalRep)).clamp(
            0.0,
            1.0,
          );

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

    if (realFromUid == toUser) {
      throw Exception("You cannot rate yourself.");
    }

    final firestore = FirebaseFirestore.instance;

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

      final raterDoc = await tx.get(raterUserRef);
      final raterData = raterDoc.data() ?? {};
      final raterName = (raterData['name'] as String?)?.isNotEmpty == true
          ? raterData['name'] as String
          : (realFromName.isNotEmpty ? realFromName : 'Student');
      final raterCredibility =
          (raterData['credibility'] as num?)?.toDouble() ?? 0.1;

      final d = targetDoc.data()!;
      final oldRep = (d['reputation'] as num?)?.toDouble() ?? 0.0;

      final ratingValue0to1 = rating / 5.0;
      final weightedRating = ratingValue0to1 * raterCredibility;

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

      final newRep = oldRep == 0
          ? weightedRating
          : (oldRep * 0.7) + (weightedRating * 0.3);

      tx.update(targetUserRef, {
        'totalRatingsReceived': FieldValue.increment(1),
        'reputation': newRep,
      });

      tx.update(raterUserRef, {'totalRatingsGiven': FieldValue.increment(1)});

      return raterCredibility;
    });

    await _recalculatePeerScore(toUser);

    return appliedCredibility;
  }

  Future<void> penalizeStudent({
    required String studentId,
    required String reportId,
    double penaltyAmount = 0.1,
  }) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((transaction) async {

      final userRef = firestore.collection('users').doc(studentId);
      final userSnap = await transaction.get(userRef);

      if (!userSnap.exists) {
        throw Exception('Student not found');
      }

      final userData = userSnap.data() as Map<String, dynamic>;
      final currentRep = (userData['reputation'] as num?)?.toDouble() ?? 0.0;
      final cgpa = (userData['cgpa_score'] as num?)?.toDouble() ?? 0.0;

      final newRep = (currentRep - penaltyAmount).clamp(0.0, 1.0);

      final normalizedCgpa = cgpa / 10.0;
      final newCredibility =
          ((0.6 * normalizedCgpa) + (0.4 * newRep)).clamp(0.0, 1.0);

      transaction.update(userRef, {
        'reputation': newRep,
        'credibility': newCredibility,
      });

      final reportRef = firestore.collection('reports').doc(reportId);
      transaction.update(reportRef, {
        'status': 'resolved_penalized',
      });
    });
  }

  Future<void> approveAchievement({
    required String postId,
    required String authorId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    const double approvalBoost = 0.02;

    await firestore.runTransaction((transaction) async {

      final postRef = firestore.collection('posts').doc(postId);
      final postSnap = await transaction.get(postRef);

      if (!postSnap.exists) {
        throw Exception('Achievement post not found.');
      }

      final postData = postSnap.data()!;
      if (postData['status'] == 'approved') {
        throw Exception('This post has already been approved.');
      }

      final userRef = firestore.collection('users').doc(authorId);
      final userSnap = await transaction.get(userRef);

      if (!userSnap.exists) {
        throw Exception('Author not found.');
      }

      final userData = userSnap.data()!;
      final currentPeerScore =
          (userData['peer_score'] as num?)?.toDouble() ?? 0.0;
      final cgpa =
          (userData['cgpa_score'] as num?)?.toDouble() ?? 0.0;
      final teacherScore =
          (userData['teacher_score'] as num?)?.toDouble() ?? 0.0;

      final newPeerScore =
          (currentPeerScore + approvalBoost).clamp(0.0, 1.0);

      final normalizedCgpa = cgpa / 10.0;
      final totalReputation =
          (newPeerScore * 0.5) + (normalizedCgpa * 0.3) + (teacherScore * 0.2);
      final newCredibility =
          ((0.6 * normalizedCgpa) + (0.4 * totalReputation)).clamp(0.0, 1.0);

      transaction.update(postRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {
        'peer_score': newPeerScore,
        'reputation': totalReputation,
        'credibility': newCredibility,
      });
    });
  }

  Future<void> submitTeacherRating({
    required String toUser,
    required int rating,
    String comment = '',
  }) async {
    final realFromUid = FirebaseAuth.instance.currentUser!.uid;
    final realFromName =
        FirebaseAuth.instance.currentUser!.displayName ?? 'Teacher';

    if (realFromUid == toUser) {
      throw Exception("You cannot rate yourself.");
    }

    final firestore = FirebaseFirestore.instance;

    final lastRatingSnap = await firestore
        .collection('ratings')
        .where('fromUser', isEqualTo: realFromUid)
        .where('toUser', isEqualTo: toUser)
        .where('type', isEqualTo: 'teacher')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastRatingSnap.docs.isNotEmpty) {
      final lastDoc = lastRatingSnap.docs.first.data();
      final lastTimestamp = lastDoc['timestamp'];
      if (lastTimestamp != null) {
        final lastDate = (lastTimestamp as dynamic).toDate() as DateTime;
        final daysSince = DateTime.now().difference(lastDate).inDays;
        if (daysSince < 7) {
          final targetDoc = await firestore
              .collection('users')
              .doc(toUser)
              .get();
          final targetName =
              (targetDoc.data()?['name'] as String?) ?? 'this student';
          final daysLeft = 7 - daysSince;
          throw Exception(
            'You already submitted an assessment for $targetName recently. You can rate them again in $daysLeft days',
          );
        }
      }
    }

    final ratingDocRef = firestore.collection('ratings').doc();

    final ratingValue0to1 = rating / 5.0;

    await ratingDocRef.set({
      'fromUser': realFromUid,
      'toUser': toUser,
      'toId': toUser,
      'rating': rating,
      'ratingValue': ratingValue0to1,
      'type': 'teacher',
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
      'fromUserName': realFromName,
      'fromName': realFromName,
    });

    await _recalculateTeacherScore(toUser);
  }

  Future<void> _recalculateTeacherScore(String userId) async {
    final firestore = FirebaseFirestore.instance;

    final ratingsSnap = await firestore
        .collection('ratings')
        .where('toUser', isEqualTo: userId)
        .where('type', isEqualTo: 'teacher')
        .get();

    if (ratingsSnap.docs.isEmpty) return;

    final allRatings = ratingsSnap.docs.map((doc) {
      final data = doc.data();
      return ((data['rating'] as num?)?.toDouble() ?? 0.0) / 5.0;
    }).toList();

    final average = allRatings.reduce((a, b) => a + b) / allRatings.length;
    final teacherScore = average.clamp(0.0, 1.0);

    final userDoc = await firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final normalizedCGPA = parseDouble(userData['cgpa_score']) / 10.0;
    final peerScore = parseDouble(userData['peer_score']);

    final totalReputation =
        (peerScore * 0.5) + (normalizedCGPA * 0.3) + (teacherScore * 0.2);

    final credibility = ((0.6 * normalizedCGPA) + (0.4 * totalReputation))
        .clamp(0.0, 1.0);

    await firestore.collection('users').doc(userId).update({
      'teacher_score': teacherScore,
      'reputation': totalReputation,
      'credibility': credibility,
    });
  }

  Future<void> _recalculatePeerScore(String userId) async {
    final firestore = FirebaseFirestore.instance;

    final ratingsSnap = await firestore
        .collection('ratings')
        .where('toUser', isEqualTo: userId)
        .where('type', isNotEqualTo: 'teacher')
        .get();

    if (ratingsSnap.docs.isEmpty) return;

    final allWeighted = ratingsSnap.docs.map((doc) {
      final data = doc.data();
      if (data.containsKey('weightedRating')) {
        return (data['weightedRating'] as num?)?.toDouble() ?? 0.0;
      }
      return ((data['rating'] as num?)?.toDouble() ?? 0.0) / 5.0;
    }).toList();

    final average = allWeighted.reduce((a, b) => a + b) / allWeighted.length;

    final peerScore = average.clamp(0.0, 1.0);

    final userDoc = await firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final normalizedCGPA = parseDouble(userData['cgpa_score']) / 10.0;
    final teacherScore = parseDouble(userData['teacher_score']);

    final totalReputation =
        (peerScore * 0.5) + (normalizedCGPA * 0.3) + (teacherScore * 0.2);

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

final reputationProvider =
    StateNotifierProvider<ReputationNotifier, ReputationState>(
      (ref) => ReputationNotifier(),
    );
