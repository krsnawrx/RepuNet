import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/verify_email_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    debugPrint('firebase oops: $e');
  }

  try {
    final modes = await FlutterDisplayMode.supported;
    if (modes.isNotEmpty) {

      modes.sort((a, b) => b.refreshRate.compareTo(a.refreshRate));
      final bestMode = modes.first;
      await FlutterDisplayMode.setPreferredMode(bestMode);
      debugPrint('hz set to: ${bestMode.refreshRate}');
    }
  } catch (_) {

  }

  runApp(const ProviderScope(child: RepuNetApp()));
}

class RepuNetApp extends StatelessWidget {
  const RepuNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepuNet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(

      data: (streamUser) {

        final user = streamUser ?? ref.read(authServiceProvider).currentUser;

        Widget child;
        if (user != null) {
          if (!user.emailVerified) {
            child = const VerifyEmailScreen(key: ValueKey('verify_email'));
          } else {
            child = FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: AppTheme.navy,
                    body: Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return Scaffold(
                    backgroundColor: AppTheme.navy,
                    body: Center(
                      child: Text(
                        'Error loading user profile.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                }

                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                if (data['role'] == 'teacher') {
                  return const TeacherDashboard(
                    key: ValueKey('teacher_dashboard'),
                  );
                } else {
                  return const AppShell(key: ValueKey('app_shell'));
                }
              },
            );
          }
        } else {
          child = const LoginScreen(key: ValueKey('login'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: child,
        );
      },

      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, _) => const LoginScreen(),
    );
  }
}
