import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PostService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> createPost({
    required String title,
    required String description,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to post.');
    }

    final userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    final authorName = userDoc.exists
        ? (userDoc.data()?['name']?.toString() ?? user.displayName ?? 'Student')
        : (user.displayName ?? 'Student');

    await _firestore.collection('posts').add({
      'authorId': user.uid,
      'authorName': authorName,
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'timestamp': FieldValue.serverTimestamp(),
      'upvoters': <String>[],
      'weightedScore': 0.0,
    });
  }

  Future<void> toggleUpvote({required String postId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to upvote.');
    }

    final voterUid = user.uid;

    await _firestore.runTransaction((transaction) async {

      final postRef = _firestore.collection('posts').doc(postId);
      final postSnap = await transaction.get(postRef);

      if (!postSnap.exists) {
        throw Exception('Post not found.');
      }

      final postData = postSnap.data()!;
      final authorId = postData['authorId']?.toString() ?? '';

      if (authorId == voterUid) {
        throw Exception('You cannot upvote your own post.');
      }

      final upvoters = List<String>.from(postData['upvoters'] ?? []);
      final currentScore =
          (postData['weightedScore'] as num?)?.toDouble() ?? 0.0;

      final voterRef = _firestore.collection('users').doc(voterUid);
      final voterSnap = await transaction.get(voterRef);
      final voterCredibility =
          (voterSnap.data()?['credibility'] as num?)?.toDouble() ?? 0.1;

      final bool isRemoving = upvoters.contains(voterUid);
      double newScore;

      if (isRemoving) {
        upvoters.remove(voterUid);
        newScore = (currentScore - voterCredibility).clamp(0.0, double.infinity);
      } else {
        upvoters.add(voterUid);
        newScore = currentScore + voterCredibility;
      }

      transaction.update(postRef, {
        'upvoters': upvoters,
        'weightedScore': newScore,
      });

      final authorRef = _firestore.collection('users').doc(authorId);
      final authorSnap = await transaction.get(authorRef);

      if (authorSnap.exists) {
        final authorData = authorSnap.data()!;
        final currentPeerScore =
            (authorData['peer_score'] as num?)?.toDouble() ?? 0.0;

        final postBoost = (newScore * 0.01).clamp(0.0, 0.1);
        final newPeerScore = (currentPeerScore + postBoost).clamp(0.0, 1.0);

        final normalizedCgpa =
            ((authorData['cgpa_score'] as num?)?.toDouble() ?? 0.0) / 10.0;
        final teacherScore =
            (authorData['teacher_score'] as num?)?.toDouble() ?? 0.0;

        final totalReputation =
            (newPeerScore * 0.5) + (normalizedCgpa * 0.3) + (teacherScore * 0.2);

        final newCredibility =
            ((0.6 * normalizedCgpa) + (0.4 * totalReputation)).clamp(0.0, 1.0);

        transaction.update(authorRef, {
          'peer_score': newPeerScore,
          'reputation': totalReputation,
          'credibility': newCredibility,
        });
      }
    });
  }
}
