import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glassmorphic_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LoginScreen — PRD §11 (User registration/login)
// ═══════════════════════════════════════════════════════════════════════════
//
// A minimalist glassmorphic login form on the dark navy gradient.
//
// Features:
//   • Email + password text fields inside a GlassmorphicCard
//   • "Sign In" elevated button with loading state
//   • "Create Account" toggle (switches to sign-up mode)
//   • Error display via SnackBar
//
// The form calls [AuthService.signIn] or [AuthService.signUp].
// The AuthGate in main.dart watches the auth stream and automatically
// navigates to the AppShell when login succeeds.
// ═══════════════════════════════════════════════════════════════════════════

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isTeacherLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        // Validate email format and domain
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        if (!emailRegex.hasMatch(email)) {
          _showError('Please enter a valid email address');
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        final allowedDomains = ['.com', '.edu', '.in', '.org', '.net', '.co'];
        final hasValidDomain = allowedDomains.any(
          (domain) => email.toLowerCase().endsWith(domain),
        );
        if (!hasValidDomain) {
          _showError('Please enter a valid email address');
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        await authService.signUp(email: email, password: password);
      } else {
        await authService.signIn(email: email, password: password);
      }
      // AuthGate handles navigation automatically via the auth stream.
      // AuthGate handles navigation automatically via the auth stream.
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'An authentication error occurred.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        msg = 'Invalid email or password.';
      } else if (e.code == 'wrong-password') {
        msg = 'Wrong password provided.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'An account already exists for that email.';
      }
      _showError(msg);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: AppTheme.navy.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    color: AppTheme.accent,
                    size: 40,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Enter your registered email address to receive a password reset link.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  _GlassTextField(
                    controller: resetEmailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSending
                              ? null
                              : () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSending
                              ? null
                              : () async {
                                  final email = resetEmailController.text
                                      .trim();
                                  if (email.isEmpty) {
                                    _showError(
                                      'Please enter an email address.',
                                    );
                                    return;
                                  }
                                  setState(() => isSending = true);
                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email);
                                    if (mounted) {
                                      Navigator.of(ctx).pop();
                                      _showSuccess(
                                        'Password reset link sent! Check your email.',
                                      );
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    String msg =
                                        e.message ?? 'An error occurred.';
                                    if (e.code == 'user-not-found') {
                                      msg = 'No user found with that email.';
                                    } else if (e.code == 'invalid-email') {
                                      msg =
                                          'Please enter a valid email address.';
                                    }
                                    if (mounted) {
                                      setState(() => isSending = false);
                                      Navigator.of(ctx).pop();
                                      _showError(msg);
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: isSending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send Link'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    resetEmailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        // ── Full-height gradient matching the dashboard ────────────────
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.navy, AppTheme.navyLight, AppTheme.navyMedium],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo / Branding ──────────────────────────────────
                  Icon(Icons.shield_rounded, size: 56, color: AppTheme.accent),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'RepuNet',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Campus Reputation System',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),

                  // ── Student / Teacher Toggle ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Student Login'),
                        selected: !_isTeacherLogin,
                        onSelected: (val) {
                          if (val) setState(() => _isTeacherLogin = false);
                        },
                        selectedColor: AppTheme.accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: !_isTeacherLogin
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: !_isTeacherLogin
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      ChoiceChip(
                        label: const Text('Teacher Login'),
                        selected: _isTeacherLogin,
                        onSelected: (val) {
                          if (val) setState(() => _isTeacherLogin = true);
                        },
                        selectedColor: AppTheme.accent,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: _isTeacherLogin
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: _isTeacherLogin
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceLg),

                  // ── Login Card (Glassmorphic) ────────────────────────
                  GlassmorphicCard(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spaceLg),

                        // Email field
                        _GlassTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppTheme.spaceMd),

                        // Password field
                        _GlassTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),

                        // Forgot password (only in Sign In mode)
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.accentLight,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: AppTheme.spaceLg),

                        if (!_isSignUp)
                          const SizedBox(height: AppTheme.spaceSm),

                        // Submit button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isSignUp ? 'Create Account' : 'Sign In',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceMd),

                  // ── Toggle sign-in / sign-up ─────────────────────────
                  TextButton(
                    onPressed: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign In'
                          : "Don't have an account? Create one",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _GlassTextField — text input styled for the glass card
// ═══════════════════════════════════════════════════════════════════════════

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
