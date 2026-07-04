// File: lib/features/auth/sign_up_screen.dart
// App: Enthusia
// Description: Sign Up screen. UI only for Week 1 — Create Account button
// routes directly to Home with no auth or validation. Firebase wires in
// Week 2. Sign In link goes back to Sign In screen.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/auth_input_field.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_isLoading) return;

    // Basic client-side validation
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter a username.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _errorMessage = 'Please accept the terms & privacy.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signUp(email: email, password: password);

      // Create user document in Firestore (users/{uid}) with username + email
      await FirestoreService.instance.createUserDocument(
        username: username,
        email: email,
      );

      // Ask for notification permission. User can dismiss; we don't gate signup on it.
      await NotificationService.instance.requestPermission();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AuthService.describeAuthError(e);
        });
      }
    }
  }

  void _goToSignIn() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'Create your account',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primaryStroke,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Takes less than a minute',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.headingMid,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthInputField(
                  label: 'Username',
                  controller: _usernameController,
                  hint: 'Name',
                ),
                const SizedBox(height: AppSpacing.s),
                AuthInputField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.s),
                AuthInputField(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Password',
                  obscureText: _obscurePassword,
                  helperText: 'At least 8 characters',
                  trailingInside: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                GestureDetector(
                  onTap: () =>
                      setState(() => _termsAccepted = !_termsAccepted),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _termsAccepted
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _termsAccepted
                                ? AppColors.accent
                                : AppColors.muted,
                            width: 2,
                          ),
                        ),
                        child: _termsAccepted
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: AppColors.onPrimary,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'terms & privacy',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.active,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                PrimaryButton(
                  label: 'Create Account',
                  onPressed: _isLoading ? null : _createAccount,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.m),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already have an account?',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      GestureDetector(
                        onTap: _goToSignIn,
                        child: Text(
                          'Sign In',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
