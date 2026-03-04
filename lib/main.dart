import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'screens/verify_email_screen.dart';
import 'theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// main.dart — App Entry Point with AuthGate + 120Hz Unlock
// ═══════════════════════════════════════════════════════════════════════════
//
// Architecture:
//   ProviderScope → RepuNetApp → AuthGate
//                                  ├── LoginScreen  (if unauthenticated)
//                                  └── AppShell     (if authenticated)
//
// The AuthGate watches [authStateProvider], which emits:
//   • null  → user is not logged in  → show LoginScreen
//   • AppUser → user is logged in    → show AppShell
//
// High Refresh Rate:
//   FlutterDisplayMode.setHighRefreshRate() is called before runApp()
//   to force the device (Dimensity 8400 Ultra) into 120Hz/144Hz mode.
//   Combined with the AndroidManifest meta-data tag, this ensures the
//   Flutter engine renders at the highest available refresh rate.
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // ── Unlock high refresh rate (120Hz / 144Hz) ────────────────────────
  // setHighRefreshRate() is unreliable on MediaTek chipsets.
  // Instead, we enumerate all available display modes, find the one
  // with the highest refresh rate, and force it via setPreferredMode().
  try {
    final modes = await FlutterDisplayMode.supported;
    if (modes.isNotEmpty) {
      // Sort by refresh rate descending, pick the fastest.
      modes.sort((a, b) => b.refreshRate.compareTo(a.refreshRate));
      final bestMode = modes.first;
      await FlutterDisplayMode.setPreferredMode(bestMode);
      debugPrint(
        'Display: ${bestMode.width}×${bestMode.height} '
        '@ ${bestMode.refreshRate}Hz',
      );
    }
  } catch (_) {
    // Silently ignore — app still runs at default rate on emulators.
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

// ═══════════════════════════════════════════════════════════════════════════
// AuthGate — Route guard based on authentication state
// ═══════════════════════════════════════════════════════════════════════════
//
// Watches the auth stream and renders either:
//   • LoginScreen — if the user is not signed in.
//   • AppShell    — if the user is authenticated.
//
// The stream is a [StreamProvider<AppUser?>] from auth_provider.dart.
// On login success, the AuthService pushes an AppUser into the stream,
// which causes this widget to rebuild and show the AppShell.
// On logout, it pushes null, which shows LoginScreen again.
// ═══════════════════════════════════════════════════════════════════════════

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // ── Authenticated ─────────────────────────────────────────────
      data: (user) {
        Widget child;
        if (user != null) {
          if (!user.emailVerified) {
            child = const VerifyEmailScreen(key: ValueKey('verify_email'));
          } else {
            child = const AppShell(key: ValueKey('app_shell'));
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

      // ── Loading (initial stream subscription) ─────────────────────
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      // ── Error ─────────────────────────────────────────────────────
      error: (error, _) => const LoginScreen(),
    );
  }
}
