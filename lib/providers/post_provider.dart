import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement_post.dart';
import '../services/post_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Post Provider — Riverpod state management for Achievement Posts
// ═══════════════════════════════════════════════════════════════════════════

/// Singleton PostService instance.
final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});

/// Real-time stream of all achievement posts, sorted by timestamp descending.
///
/// Sorts locally to avoid requiring a Firestore composite index.
/// Wraps parsing in try-catch per document to prevent a single malformed
/// doc from crashing the entire stream (e.g. pending server timestamp).
final postsStreamProvider = StreamProvider<List<AchievementPost>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .snapshots()
      .map((snapshot) {
    final List<AchievementPost> posts = [];

    for (final doc in snapshot.docs) {
      try {
        // Skip documents still pending server timestamp confirmation
        // (hasPendingWrites = true AND timestamp = null)
        final data = doc.data();
        if (doc.metadata.hasPendingWrites && data['timestamp'] == null) {
          continue;
        }
        posts.add(AchievementPost.fromMap(doc.id, data));
      } catch (e) {
        // Log but don't crash the stream — lets the rest of the feed load
        // ignore: avoid_print
        print('⚠️ PostsFeed: Skipping doc ${doc.id} — $e');
      }
    }

    posts.sort((a, b) {
      final timeA =
          a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB =
          b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA); // Newest first
    });

    return posts;
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// PostActionNotifier — handles create & upvote with loading/error states
// ═══════════════════════════════════════════════════════════════════════════

enum PostActionStatus { idle, loading, success, error }

class PostActionState {
  final PostActionStatus status;
  final String? errorMessage;

  const PostActionState({
    this.status = PostActionStatus.idle,
    this.errorMessage,
  });
}

class PostActionNotifier extends StateNotifier<PostActionState> {
  final PostService _service;

  PostActionNotifier(this._service) : super(const PostActionState());

  Future<void> createPost({
    required String title,
    required String description,
    required String category,
  }) async {
    state = const PostActionState(status: PostActionStatus.loading);
    try {
      await _service.createPost(
        title: title,
        description: description,
        category: category,
      );
      state = const PostActionState(status: PostActionStatus.success);
    } catch (e) {
      state = PostActionState(
        status: PostActionStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> toggleUpvote({required String postId}) async {
    try {
      await _service.toggleUpvote(postId: postId);
    } catch (e) {
      state = PostActionState(
        status: PostActionStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void resetState() {
    state = const PostActionState();
  }
}

final postActionProvider =
    StateNotifierProvider<PostActionNotifier, PostActionState>((ref) {
  return PostActionNotifier(ref.watch(postServiceProvider));
});
