import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PostService — Achievement Posts CRUD + Credibility-Weighted Upvotes
// ═══════════════════════════════════════════════════════════════════════════
//
// Writes to Firestore `posts` collection.
//
// createPost   — Simple document write with server timestamp.
// toggleUpvote — Atomic Firestore Transaction that:
//                  1. Reads the voter's `credibility` from `users/{uid}`
//                  2. Adds/removes UID from `upvoters` array
//                  3. Increments/decrements `weightedScore` by credibility
//                  4. Updates the post author's `peer_score` with a capped
//                     boost derived from the post's total weighted score.
//
// Guards:
//   • Must be logged in
//   • Cannot upvote your own post
// ═══════════════════════════════════════════════════════════════════════════

class PostService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PostService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ─── Create Post ──────────────────────────────────────────────────────
  /// Creates a new achievement post in the `posts` collection.
  ///
  /// The author's display name is denormalized into the document for
  /// feed rendering performance (avoids N+1 user lookups).
  Future<void> createPost({
    required String title,
    required String description,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to post.');
    }

    // Fetch the author's name from Firestore for denormalization
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

  // ─── Toggle Upvote (Atomic Transaction) ───────────────────────────────
  /// Toggles the current user's credibility-weighted upvote on a post.
  ///
  /// Uses a Firestore Transaction to ensure atomicity:
  ///   - If NOT yet upvoted: adds UID, increments weightedScore by credibility
  ///   - If ALREADY upvoted: removes UID, decrements weightedScore by credibility
  ///
  /// After updating the post, the author's `peer_score` in the `users`
  /// collection is recalculated with a capped boost.
  Future<void> toggleUpvote({required String postId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to upvote.');
    }

    final voterUid = user.uid;

    await _firestore.runTransaction((transaction) async {
      // 1. Read the post document
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

      // 2. Read the voter's credibility from users collection
      final voterRef = _firestore.collection('users').doc(voterUid);
      final voterSnap = await transaction.get(voterRef);
      final voterCredibility =
          (voterSnap.data()?['credibility'] as num?)?.toDouble() ?? 0.1;

      // 3. Toggle the upvote
      final bool isRemoving = upvoters.contains(voterUid);
      double newScore;

      if (isRemoving) {
        upvoters.remove(voterUid);
        newScore = (currentScore - voterCredibility).clamp(0.0, double.infinity);
      } else {
        upvoters.add(voterUid);
        newScore = currentScore + voterCredibility;
      }

      // 4. Write the updated post
      transaction.update(postRef, {
        'upvoters': upvoters,
        'weightedScore': newScore,
      });

      // 5. Read the author's user document for peer_score update
      final authorRef = _firestore.collection('users').doc(authorId);
      final authorSnap = await transaction.get(authorRef);

      if (authorSnap.exists) {
        final authorData = authorSnap.data()!;
        final currentPeerScore =
            (authorData['peer_score'] as num?)?.toDouble() ?? 0.0;

        // Capped boost: min(0.1, totalWeightedScore * 0.01)
        // This prevents upvote farming from breaking the 0.0–1.0 scale.
        final postBoost = (newScore * 0.01).clamp(0.0, 0.1);
        final newPeerScore = (currentPeerScore + postBoost).clamp(0.0, 1.0);

        final normalizedCgpa =
            ((authorData['cgpa_score'] as num?)?.toDouble() ?? 0.0) / 10.0;
        final teacherScore =
            (authorData['teacher_score'] as num?)?.toDouble() ?? 0.0;

        // Total Reputation: (peer * 0.5) + (cgpa * 0.3) + (teacher * 0.2)
        final totalReputation =
            (newPeerScore * 0.5) + (normalizedCgpa * 0.3) + (teacherScore * 0.2);

        // Credibility: (0.6 × cgpa) + (0.4 × totalRep)
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
