import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AchievementPost Model
// ═══════════════════════════════════════════════════════════════════════════
//
// Maps to the Firestore `posts` collection:
//
//   id            : auto-generated doc ID
//   authorId      : uid of the poster
//   authorName    : display name of the poster (denormalized for feed perf)
//   title         : short achievement headline
//   description   : full description / context
//   category      : one of Hackathon | Project | Research | Certification
//   timestamp     : server timestamp
//   upvoters      : List<String> of UIDs who credibility-upvoted
//   weightedScore : cumulative sum of each upvoter's credibility weight
//
// ═══════════════════════════════════════════════════════════════════════════

/// The four recognized achievement categories.
enum PostCategory {
  hackathon('Hackathon'),
  project('Project'),
  research('Research'),
  certification('Certification');

  const PostCategory(this.label);
  final String label;

  /// Parses a Firestore string back into an enum value.
  static PostCategory fromString(String? value) {
    return PostCategory.values.firstWhere(
      (e) => e.label.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => PostCategory.project,
    );
  }
}

class AchievementPost {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String description;
  final PostCategory category;
  final DateTime? timestamp;
  final List<String> upvoters;
  final double weightedScore;

  const AchievementPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.category,
    this.timestamp,
    this.upvoters = const [],
    this.weightedScore = 0.0,
  });

  /// Factory to create an [AchievementPost] from a Firestore document map.
  factory AchievementPost.fromMap(String id, Map<String, dynamic> data) {
    return AchievementPost(
      id: id,
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'Unknown',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: PostCategory.fromString(data['category']?.toString()),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      upvoters: List<String>.from(data['upvoters'] ?? []),
      weightedScore: (data['weightedScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts to a Firestore-compatible map for writes.
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'description': description,
      'category': category.label,
      'timestamp': FieldValue.serverTimestamp(),
      'upvoters': upvoters,
      'weightedScore': weightedScore,
    };
  }

  /// Whether a given UID has already upvoted this post.
  bool hasUpvoted(String uid) => upvoters.contains(uid);
}
