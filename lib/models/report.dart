import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedId;
  final String reason;
  final String details;
  final String status;
  final DateTime? timestamp;

  const Report({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedId,
    required this.reason,
    required this.details,
    required this.status,
    this.timestamp,
  });

  factory Report.fromMap(String id, Map<String, dynamic> data) {
    return Report(
      id: id,
      reporterId: data['reporterId']?.toString() ?? '',
      reporterName: data['reporterName']?.toString() ?? '',
      reportedId: data['reportedId']?.toString() ?? '',
      reason: data['reason']?.toString() ?? 'Unknown',
      details: data['details']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedId': reportedId,
      'reason': reason,
      'details': details,
      'status': status,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }
}
