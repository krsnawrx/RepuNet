import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement_post.dart';
import '../services/post_service.dart';

final postServiceProvider = Provider<PostService>((ref) {
  return PostService();
});

final postsStreamProvider = StreamProvider<List<AchievementPost>>((ref) {
  return FirebaseFirestore.instance
      .collection('posts')
      .snapshots()
      .map((snapshot) {
    final List<AchievementPost> posts = [];

    for (final doc in snapshot.docs) {
      try {

        final data = doc.data();
        if (doc.metadata.hasPendingWrites && data['timestamp'] == null) {
          continue;
        }
        posts.add(AchievementPost.fromMap(doc.id, data));
      } catch (e) {

        print('doc skip: $e');
      }
    }

    posts.sort((a, b) {
      final timeA =
          a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final timeB =
          b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return timeB.compareTo(timeA);
    });

    return posts;
  });
});

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
