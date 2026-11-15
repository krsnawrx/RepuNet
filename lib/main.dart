import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

const Color kNavy = Color(0xFF0A1128);
const Color kNavyLight = Color(0xFF1B2845);
const Color kAccent = Color(0xFF3A86FF);
const Color kTeal = Color(0xFF06D6A0);
const Color kError = Color(0xFFEF476F);
const Color kWarn = Color(0xFFFFD166);

final _auth = FirebaseAuth.instance;
final _db = FirebaseFirestore.instance;

double _rep(Map d) {
  double p(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
  final peer = p(d['peer_score']);
  final cgpa = p(d['cgpa_score']) / 10.0;
  final teacher = p(d['teacher_score']);
  return (peer * 0.5) + (cgpa * 0.3) + (teacher * 0.2);
}

String _initials(String n) {
  if (n.trim().isEmpty) return '?';
  final w = n.trim().split(' ');
  return w.length >= 2 ? '${w[0][0]}${w[1][0]}'.toUpperCase() : w[0][0].toUpperCase();
}

Color _repColor(double s) => s >= 0.75 ? kTeal : s >= 0.40 ? kWarn : kError;

String _tier(double s) => s >= 0.75 ? 'High Standing' : s >= 0.40 ? 'Moderate' : 'Rising';

void _snack(BuildContext ctx, String msg, {bool err = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: err ? kError : kTeal,
    behavior: SnackBarBehavior.floating,
  ));
}

Widget _field(TextEditingController c, String label, {bool pass = false, TextInputType? type}) {
  return TextField(
    controller: c,
    obscureText: pass,
    keyboardType: type,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white10,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 1.5)),
    ),
  );
}

Widget _card({required Widget child, EdgeInsets? padding}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(18),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withAlpha(28)),
    ),
    child: child,
  );
}

Widget _btn(String label, VoidCallback? onTap, {bool loading = false, Color bg = kAccent}) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    ),
  );
}

Widget _bg(Widget child) => Container(
  width: double.infinity,
  height: double.infinity,
  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [kNavy, kNavyLight, Color(0xFF274060)])),
  child: child,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _firebaseOptions());
  runApp(const RepuNetApp());
}

FirebaseOptions _firebaseOptions() {
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
    return const FirebaseOptions(apiKey: 'AIzaSyBgAggFRMXkwMkL4En_zj9mVsxu1NNQxu0', appId: '1:841694596350:web:fc93f071d583d5de2529af', messagingSenderId: '841694596350', projectId: 'repunet-86ae6', authDomain: 'repunet-86ae6.firebaseapp.com', storageBucket: 'repunet-86ae6.firebasestorage.app');
  }
  return const FirebaseOptions(apiKey: 'AIzaSyAc43Bj28tRw6tKM5Sn38qg8PDEqRP6N9Q', appId: '1:841694596350:android:46fe700d9d8d23582529af', messagingSenderId: '841694596350', projectId: 'repunet-86ae6', storageBucket: 'repunet-86ae6.firebasestorage.app');
}

class RepuNetApp extends StatelessWidget {
  const RepuNetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepuNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: kNavy),
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Scaffold(backgroundColor: kNavy, body: Center(child: CircularProgressIndicator(color: kAccent)));
          if (snap.data == null) return const LoginScreen();
          return FutureBuilder<DocumentSnapshot>(
            future: _db.collection('users').doc(snap.data!.uid).get(),
            builder: (ctx2, userSnap) {
              if (!userSnap.hasData) return const Scaffold(backgroundColor: kNavy, body: Center(child: CircularProgressIndicator(color: kAccent)));
              final role = (userSnap.data?.data() as Map?)?.cast<String, dynamic>()['role'] ?? 'student';
              return role == 'teacher' ? const TeacherScreen() : const StudentShell();
            },
          );
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _isSignUp = false, _loading = false;

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _pass.text.trim().isEmpty) { _snack(context, 'Fill all fields.', err: true); return; }
    if (_isSignUp && _name.text.trim().isEmpty) { _snack(context, 'Enter your name.', err: true); return; }
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        final cred = await _auth.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
        await _db.collection('users').doc(cred.user!.uid).set({
          'name': _name.text.trim(), 'email': _email.text.trim(), 'role': 'student',
          'peer_score': 0.0, 'cgpa_score': 0.0, 'teacher_score': 0.0, 'reputation': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _auth.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _snack(context, e.message ?? 'Auth error', err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _bg(SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        const Icon(Icons.shield_rounded, size: 56, color: kAccent),
        const SizedBox(height: 8),
        const Text('RepuNet', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
        const Text('Campus Reputation System', style: TextStyle(color: Colors.white38)),
        const SizedBox(height: 32),
        _card(child: Column(children: [
          Text(_isSignUp ? 'Create Account' : 'Sign In', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          if (_isSignUp) ...[_field(_name, 'Full Name'), const SizedBox(height: 12)],
          _field(_email, 'Email', type: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _field(_pass, 'Password', pass: true),
          const SizedBox(height: 20),
          _btn(_isSignUp ? 'Create Account' : 'Sign In', _submit, loading: _loading),
        ])),
        TextButton(onPressed: () => setState(() => _isSignUp = !_isSignUp), child: Text(_isSignUp ? 'Already have an account? Sign In' : "Don't have an account? Create one", style: const TextStyle(color: kAccent))),
      ]))))),
    );
  }
}

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _idx = 0;
  final _pages = const [DashboardTab(), LeaderboardTab(), SearchTab(), ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        backgroundColor: kNavyLight,
        selectedItemColor: kAccent,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard_rounded), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    return _bg(SafeArea(child: StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kAccent));
        final d = (snap.data!.data() as Map?)?.cast<String, dynamic>() ?? {};
        final name = d['name'] ?? 'Student';
        final peer = (d['peer_score'] as num?)?.toDouble() ?? 0.0;
        final cgpa = (d['cgpa_score'] as num?)?.toDouble() ?? 0.0;
        final teacher = (d['teacher_score'] as num?)?.toDouble() ?? 0.0;
        final score = _rep(d);
        final col = _repColor(score);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 14)),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('Reputation Score', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Text(score.toStringAsFixed(3), style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: col)),
            Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: col.withAlpha(38), borderRadius: BorderRadius.circular(20)), child: Text(_tier(score), style: TextStyle(color: col, fontWeight: FontWeight.bold))),
          ])),
          const SizedBox(height: 8),
          _card(child: Column(children: [
            const Text('Score Breakdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _scoreRow('Peer Score (50%)', peer, kAccent),
            _scoreRow('CGPA Score (30%)', cgpa / 10.0, kTeal),
            _scoreRow('Teacher Score (20%)', teacher, kWarn),
            const Divider(color: Colors.white12, height: 24),
            Row(children: [const Text('Reputation =', style: TextStyle(color: Colors.white70)), const Spacer(), Text('(P×0.5) + (C×0.3) + (T×0.2)', style: TextStyle(color: Colors.white38, fontSize: 12))]),
            const SizedBox(height: 4),
            Text('= ${score.toStringAsFixed(4)}', style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 16)),
          ])),
        ]);
      },
    )));
  }

  Widget _scoreRow(String label, double val, Color c) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
      Text(val.toStringAsFixed(3), style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    ]));
  }
}

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser!.uid;
    return _bg(SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 8), child: Text('Leaderboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').orderBy('reputation', descending: true).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kAccent));
          final docs = snap.data!.docs.where((d) => (d.data() as Map)['role'] != 'teacher').toList();
          return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = (docs[i].data() as Map).cast<String, dynamic>();
            final uid = docs[i].id;
            final name = d['name'] ?? 'Unknown';
            final score = (d['reputation'] as num?)?.toDouble() ?? 0.0;
            final col = _repColor(score);
            final isMe = uid == me;
            final medals = ['🥇', '🥈', '🥉'];
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => StudentProfileScreen(uid: uid))),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: isMe ? kAccent.withAlpha(46) : Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(14), border: Border.all(color: isMe ? kAccent.withAlpha(100) : Colors.white.withAlpha(20))),
                child: Row(children: [
                  SizedBox(width: 32, child: Text(i < 3 ? medals[i] : '#${i + 1}', style: const TextStyle(fontSize: 16))),
                  CircleAvatar(backgroundColor: col.withAlpha(46), child: Text(_initials(name), style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 13))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), if (isMe) const Text('  YOU', style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
                  ])),
                  Text(score.toStringAsFixed(3), style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            );
          });
        },
      )),
    ])));
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser!.uid;
    return _bg(SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 8), child: Text('Campus Directory', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
        controller: _ctrl, onChanged: (v) => setState(() => _q = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: 'Search by name...', hintStyle: const TextStyle(color: Colors.white38), prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54), filled: true, fillColor: Colors.white.withAlpha(28), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          suffixIcon: _q.isNotEmpty ? IconButton(icon: const Icon(Icons.close, color: Colors.white38), onPressed: () { _ctrl.clear(); setState(() => _q = ''); }) : null),
      )),
      const SizedBox(height: 8),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').orderBy('name').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kAccent));
          final docs = snap.data!.docs.where((d) {
            if (d.id == me) return false;
            final data = d.data() as Map;
            if (data['role'] == 'teacher') return false;
            if (_q.isEmpty) return true;
            return (data['name'] ?? '').toString().toLowerCase().contains(_q.toLowerCase());
          }).toList();
          return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = (docs[i].data() as Map).cast<String, dynamic>();
            final uid = docs[i].id;
            final name = d['name'] ?? 'Unknown';
            final score = _rep(d);
            final col = _repColor(score);
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => StudentProfileScreen(uid: uid))),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withAlpha(20))),
                child: Row(children: [
                  CircleAvatar(backgroundColor: kAccent.withAlpha(46), child: Text(_initials(name), style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text('CGPA ${((d['cgpa_score'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ])),
                  Text(score.toStringAsFixed(3), style: TextStyle(color: col, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.star_half_rounded, color: kWarn), onPressed: () => _showRateSheet(context, uid, name)),
                ]),
              ),
            );
          });
        },
      )),
    ])));
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    return _bg(SafeArea(child: StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (ctx, snap) {
        final d = (snap.data?.data() as Map?)?.cast<String, dynamic>() ?? {};
        final name = d['name'] ?? 'Student';
        final email = d['email'] ?? _auth.currentUser?.email ?? '';
        final cgpa = (d['cgpa_score'] as num?)?.toDouble() ?? 0.0;
        final score = _rep(d);
        final col = _repColor(score);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: Column(children: [
            const SizedBox(height: 16),
            CircleAvatar(radius: 44, backgroundColor: kAccent.withAlpha(46), child: Text(_initials(name), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kAccent))),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(email, style: const TextStyle(color: Colors.white38)),
          ])),
          const SizedBox(height: 20),
          _card(child: Column(children: [
            _infoRow(Icons.school_rounded, 'CGPA', cgpa.toStringAsFixed(2)),
            _infoRow(Icons.star_rounded, 'Reputation', score.toStringAsFixed(3)),
            _infoRow(Icons.emoji_events_rounded, 'Standing', _tier(score)),
          ])),
          const SizedBox(height: 8),
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Score Formula', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Text('reputation = (peerScore × 0.5) + (cgpaScore ÷ 10 × 0.3) + (teacherScore × 0.2)', style: TextStyle(color: Colors.white.withAlpha(153), fontSize: 13, height: 1.5)),
            const SizedBox(height: 8),
            Text('Your score: ${score.toStringAsFixed(4)}', style: TextStyle(color: col, fontWeight: FontWeight.bold)),
          ])),
          const SizedBox(height: 16),
          _btn('Sign Out', () async { await _auth.signOut(); }, bg: kError),
        ]);
      },
    )));
  }

  Widget _infoRow(IconData icon, String label, String val) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
      Icon(icon, color: kAccent, size: 20), const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: Colors.white70)),
      const Spacer(),
      Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]));
  }
}

class StudentProfileScreen extends StatelessWidget {
  final String uid;
  const StudentProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser!.uid;
    final isSelf = me == uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile'), backgroundColor: kNavy, iconTheme: const IconThemeData(color: Colors.white)),
      body: _bg(StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('users').doc(uid).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kAccent));
          final d = (snap.data!.data() as Map?)?.cast<String, dynamic>() ?? {};
          final name = d['name'] ?? 'Student';
          final course = d['course'] ?? '';
          final branch = d['branch'] ?? '';
          final cgpa = (d['cgpa_score'] as num?)?.toDouble() ?? 0.0;
          final score = _rep(d);
          final col = _repColor(score);
          return ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: CircleAvatar(radius: 48, backgroundColor: kAccent.withAlpha(46), child: Text(_initials(name), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: kAccent)))),
            const SizedBox(height: 12),
            Center(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
            if (course.isNotEmpty || branch.isNotEmpty)
              Center(child: Text('$course • $branch', style: const TextStyle(color: Colors.white38))),
            const SizedBox(height: 20),
            _card(child: Column(children: [
              Text(score.toStringAsFixed(3), style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: col)),
              Text('Reputation Score', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: col.withAlpha(38), borderRadius: BorderRadius.circular(20)), child: Text(_tier(score), style: TextStyle(color: col, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('CGPA', cgpa.toStringAsFixed(1), kTeal),
                _stat('Peer', (d['peer_score'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00', kAccent),
                _stat('Teacher', (d['teacher_score'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00', kWarn),
              ]),
            ])),
            if (!isSelf) ...[
              const SizedBox(height: 12),
              _btn('⭐ Rate Student', () => _showRateSheet(context, uid, name)),
            ],
          ]);
        },
      )),
    );
  }

  Widget _stat(String label, String val, Color c) {
    return Column(children: [Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c)), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))]);
  }
}

void _showRateSheet(BuildContext context, String toUid, String toName) {
  int rating = 3;
  bool loading = false;
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      return Container(
        margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: kNavyLight, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Rate $toName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) {
            final val = i + 1;
            return IconButton(icon: Icon(val <= rating ? Icons.star_rounded : Icons.star_border_rounded, color: kWarn, size: 36), onPressed: () => setState(() => rating = val));
          })),
          const SizedBox(height: 20),
          _btn('Submit Rating', loading ? null : () async {
            setState(() => loading = true);
            final me = _auth.currentUser!.uid;
            final messenger = ScaffoldMessenger.of(context);
            if (me == toUid) { if (ctx.mounted) Navigator.pop(ctx); messenger.showSnackBar(const SnackBar(content: Text('Cannot rate yourself.'), backgroundColor: kError, behavior: SnackBarBehavior.floating)); return; }
            try {
              final last = await _db.collection('ratings').where('fromUser', isEqualTo: me).where('toUser', isEqualTo: toUid).orderBy('timestamp', descending: true).limit(1).get();
              if (last.docs.isNotEmpty) {
                final ts = last.docs.first.data()['timestamp'];
                if (ts != null) {
                  final diff = DateTime.now().difference((ts as Timestamp).toDate()).inDays;
                  if (diff < 3) { if (ctx.mounted) Navigator.pop(ctx); messenger.showSnackBar(SnackBar(content: Text('Wait ${3 - diff} more day(s) to re-rate.'), backgroundColor: kError, behavior: SnackBarBehavior.floating)); return; }
                }
              }
              final ratingVal = rating / 5.0;
              await _db.collection('ratings').add({'fromUser': me, 'toUser': toUid, 'toId': toUid, 'rating': rating, 'ratingValue': ratingVal, 'timestamp': FieldValue.serverTimestamp()});
              final snap = await _db.collection('ratings').where('toUser', isEqualTo: toUid).get();
              final avg = snap.docs.map((d) => (d.data()['ratingValue'] as num?)?.toDouble() ?? 0.0).fold(0.0, (a, b) => a + b) / snap.docs.length;
              final userD = (await _db.collection('users').doc(toUid).get()).data() ?? {};
              final cgpa = (userD['cgpa_score'] as num?)?.toDouble() ?? 0.0;
              final teacher = (userD['teacher_score'] as num?)?.toDouble() ?? 0.0;
              final newRep = (avg * 0.5) + (cgpa / 10.0 * 0.3) + (teacher * 0.2);
              await _db.collection('users').doc(toUid).update({'peer_score': avg, 'reputation': newRep});
              if (ctx.mounted) { Navigator.pop(ctx); _snack(context, 'Rating submitted!'); }
            } catch (e) {
              if (ctx.mounted) { Navigator.pop(ctx); _snack(context, e.toString(), err: true); }
            }
          }, loading: loading),
        ]),
      );
    }),
  );
}

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});
  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _idx = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: IndexedStack(index: _idx, children: const [_TeacherStudentsTab(), _TeacherProfileTab()]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, onTap: (i) => setState(() => _idx = i),
        backgroundColor: kNavyLight, selectedItemColor: kAccent, unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _TeacherStudentsTab extends StatelessWidget {
  const _TeacherStudentsTab();
  @override
  Widget build(BuildContext context) {
    return _bg(SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 8), child: Text('Student Directory', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: kAccent));
          final docs = snap.data!.docs.where((d) => (d.data() as Map)['role'] != 'teacher').toList();
          docs.sort((a, b) {
            final ra = ((a.data() as Map)['reputation'] as num?)?.toDouble() ?? 0.0;
            final rb = ((b.data() as Map)['reputation'] as num?)?.toDouble() ?? 0.0;
            return rb.compareTo(ra);
          });
          return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: docs.length, itemBuilder: (ctx, i) {
            final d = (docs[i].data() as Map).cast<String, dynamic>();
            final uid = docs[i].id;
            final name = d['name'] ?? 'Unknown';
            final score = (d['reputation'] as num?)?.toDouble() ?? 0.0;
            final col = _repColor(score);
            return GestureDetector(
              onTap: () => _showTeacherRateSheet(context, uid, name),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withAlpha(20))),
                child: Row(children: [
                  CircleAvatar(backgroundColor: kAccent.withAlpha(46), child: Text(_initials(name), style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: col.withAlpha(38), borderRadius: BorderRadius.circular(16)), child: Text(score.toStringAsFixed(3), style: TextStyle(color: col, fontWeight: FontWeight.bold))),
                ]),
              ),
            );
          });
        },
      )),
    ])));
  }
}

void _showTeacherRateSheet(BuildContext context, String toUid, String toName) {
  int tRating = 3;
  bool tLoading = false;
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: kNavyLight, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Assess $toName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) {
            final val = i + 1;
            return IconButton(icon: Icon(val <= tRating ? Icons.star_rounded : Icons.star_border_rounded, color: kAccent, size: 36), onPressed: () => setState(() => tRating = val));
          })),
          const SizedBox(height: 20),
          _btn('Submit Assessment', tLoading ? null : () async {
            setState(() => tLoading = true);
            try {
              await _db.collection('ratings').add({'fromUser': _auth.currentUser!.uid, 'toUser': toUid, 'toId': toUid, 'rating': tRating, 'ratingValue': tRating / 5.0, 'type': 'teacher', 'timestamp': FieldValue.serverTimestamp()});
              final snap = await _db.collection('ratings').where('toUser', isEqualTo: toUid).where('type', isEqualTo: 'teacher').get();
              final avg = snap.docs.map((d) => (d.data()['ratingValue'] as num?)?.toDouble() ?? 0.0).fold(0.0, (a, b) => a + b) / snap.docs.length;
              final userD = (await _db.collection('users').doc(toUid).get()).data() ?? {};
              final cgpa = (userD['cgpa_score'] as num?)?.toDouble() ?? 0.0;
              final peer = (userD['peer_score'] as num?)?.toDouble() ?? 0.0;
              final newRep = (peer * 0.5) + (cgpa / 10.0 * 0.3) + (avg * 0.2);
              await _db.collection('users').doc(toUid).update({'teacher_score': avg, 'reputation': newRep});
              if (ctx.mounted) { Navigator.pop(ctx); _snack(context, 'Assessment submitted!'); }
            } catch (e) {
              if (ctx.mounted) { Navigator.pop(ctx); _snack(context, e.toString(), err: true); }
            }
          }, loading: tLoading),
        ]),
      );
    }),
  );
}

class _TeacherProfileTab extends StatelessWidget {
  const _TeacherProfileTab();
  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? '';
    return _bg(SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircleAvatar(radius: 44, backgroundColor: Color(0x25006D6A), child: Icon(Icons.school_rounded, size: 44, color: kTeal)),
      const SizedBox(height: 16),
      const Text('Teacher Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      const SizedBox(height: 4),
      Text(email, style: const TextStyle(color: Colors.white38)),
      const SizedBox(height: 32),
      _btn('Sign Out', () async { await _auth.signOut(); }, bg: kError),
    ])))));
  }
}
