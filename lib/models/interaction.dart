// ═══════════════════════════════════════════════════════════════════════════
// Interaction Model
// ═══════════════════════════════════════════════════════════════════════════
//
// Maps to the Firestore `ratings` collection:
//
//   interactionId : auto-generated doc ID
//   fromUser      : uid of the rater
//   toUser        : uid of the person being rated
//   rating        : 1–5 integer score
//   comment       : optional text comment from the rater
//   timestamp     : when the rating was submitted
//
// An optional [fromUserName] is carried client-side for display in the
// rater list without requiring a separate user lookup.
// ═══════════════════════════════════════════════════════════════════════════

class Interaction {
  final String interactionId;
  final String fromUser;
  final String toUser;
  final int rating;
  final String comment;
  final DateTime timestamp;

  /// Display-only field — the rater's name (resolved client-side).
  final String fromUserName;

  /// Type of rating (e.g. 'peer' or 'teacher')
  final String type;

  const Interaction({
    required this.interactionId,
    required this.fromUser,
    required this.toUser,
    required this.rating,
    this.comment = '',
    required this.timestamp,
    this.fromUserName = 'Unknown',
    this.type = 'peer',
  });

  /// Factory to create an [Interaction] from a Firestore document map.
  factory Interaction.fromMap(String id, Map<String, dynamic> data) {
    return Interaction(
      interactionId: id,
      fromUser: data['fromUser'] as String? ?? '',
      toUser: data['toUser'] as String? ?? '',
      rating: data['rating'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate() as DateTime
          : DateTime.now(),
      fromUserName: (data['fromName'] as String?)?.isNotEmpty == true
          ? data['fromName'] as String
          : (data['fromUserName'] as String? ?? 'Unknown'),
      type: data['type'] as String? ?? 'peer',
    );
  }

  /// Converts to a Firestore-compatible map for writes.
  Map<String, dynamic> toMap() {
    return {
      'fromUser': fromUser,
      'toUser': toUser,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
      'fromUserName': fromUserName,
      'type': type,
    };
  }
}
