import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ReportService — Lightweight misconduct/spam reporting
// ═══════════════════════════════════════════════════════════════════════════
//
// Writes to Firestore `reports` collection.
// Each report contains:
//   reporterId   — who filed it (current user UID)
//   reportedId   — who is being reported
//   reason       — category (Spam, Harassment, Fake Score, Inappropriate Bio)
//   details      — optional free-text explanation
//   status       — defaults to 'pending'
//   timestamp    — server timestamp
//
// Guards:
//   • Must be logged in
//   • Cannot report yourself
// ═══════════════════════════════════════════════════════════════════════════

class ReportService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Submits a misconduct report to the `reports` collection.
  ///
  /// Throws if the user is not logged in or tries to report themselves.
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
