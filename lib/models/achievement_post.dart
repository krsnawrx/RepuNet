import 'package:cloud_firestore/cloud_firestore.dart';

enum PostCategory {
  hackathon('Hackathon'),
  project('Project'),
  research('Research'),
  certification('Certification');

  const PostCategory(this.label);
  final String label;

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

  bool hasUpvoted(String uid) => upvoters.contains(uid);
}
