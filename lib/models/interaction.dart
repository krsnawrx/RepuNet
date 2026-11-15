class Interaction {
  final String interactionId;
  final String fromUser;
  final String toUser;
  final int rating;
  final String comment;
  final DateTime timestamp;

  final String fromUserName;

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
