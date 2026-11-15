import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> submitReport({
    required String reportedId,
    required String reason,
    String? details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to submit a report.');
    }

    if (user.uid == reportedId) {
      throw Exception('You cannot report yourself.');
    }

    await _firestore.collection('reports').add({
      'reporterId': user.uid,
      'reporterName': user.displayName ?? 'Unknown',
      'reportedId': reportedId,
      'reason': reason,
      'details': (details ?? '').trim(),
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
