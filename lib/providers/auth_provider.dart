import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Auth Provider — PRD §10 Step 1 (Firebase Auth)
// ═══════════════════════════════════════════════════════════════════════════
//
// Manages the authentication state of the current user.
//
// CURRENT MODE: Mock auth (no Firebase config required).
//   - Simulates login/logout with a StreamController.
//   - Stores a simple user map (uid, email, name).
//
// FIREBASE MODE: When `flutterfire configure` has been run, set
//   [_useFirebase] to true and uncomment the Firebase imports.
//   The authStateProvider will then listen to
//   FirebaseAuth.instance.authStateChanges() instead.
//
// The rest of the app only depends on [authStateProvider] and
// [authServiceProvider], so the switch is seamless.
// ═══════════════════════════════════════════════════════════════════════════

/// Simple representation of the logged-in user.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.emailVerified = false,
  });
}

// ── Mock Auth Service ───────────────────────────────────────────────────────

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of auth state changes from Firebase Auth.
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        emailVerified: user.emailVerified,
      );
    });
  }

  /// The currently signed-in user, or null.
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      emailVerified: user.emailVerified,
    );
  }

  /// Signs in with email and password via Firebase Auth.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      emailVerified: user.emailVerified,
    );
  }

  /// Creates a new account with email and password via Firebase Auth.
  /// Also creates the initial user document in Firestore.
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user!;

    // Send verification email
    await user.sendEmailVerification();

    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      emailVerified: user.emailVerified,
    );
  }

  /// Refreshes the user document to check if they clicked the email verification link.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
    // Emitting a new event isn't strictly necessary as reload() often
    // triggers authStateChanges, but we can't always rely on it immediately.
    // Riverpod will rebuild if we just call it.
  }

  /// Resends the verification email to the current user.
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Signs out the current user from Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Permanently deletes the current user's account and all related data.
  ///
  /// 1. Batch-deletes all ratings where fromUser == uid
  /// 2. Batch-deletes all ratings where toUser == uid
  /// 3. Deletes the user document from users collection
  /// 4. Deletes the Firebase Auth account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in.');
    final uid = user.uid;

    // Helper: batch-delete all docs matching a query
    Future<void> batchDeleteQuery(Query query) async {
      QuerySnapshot snap = await query.get();
      while (snap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        snap = await query.get();
      }
    }

    // 1. Delete all ratings FROM this user
    await batchDeleteQuery(
      _firestore.collection('ratings').where('fromUser', isEqualTo: uid),
    );

    // 2. Delete all ratings TO this user
    await batchDeleteQuery(
      _firestore.collection('ratings').where('toUser', isEqualTo: uid),
    );

    // 3. Delete the user document
    await _firestore.collection('users').doc(uid).delete();

    // 4. Delete the Firebase Auth account
    await user.delete();
  }

  /// Cleans up resources (none needed for Firebase instances).
  void dispose() {}
}

// ── Riverpod Providers ──────────────────────────────────────────────────────

/// Singleton auth service instance.
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider that emits the current auth state.
///
/// Used by the AuthGate in main.dart:
///   ref.watch(authStateProvider).when(
///     data: (user) => user != null ? AppShell() : LoginScreen(),
///     ...
///   );
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});
