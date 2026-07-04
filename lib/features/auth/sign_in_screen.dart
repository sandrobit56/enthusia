// File: lib/features/auth/sign_in_screen.dart
// App: Enthusia
// Description: Sign In screen. UI only for Week 1 — Sign In button routes
// directly to Home with no auth. Firebase wires in Week 2. Sign Up link
// navigates to Sign Up screen. Forgot link navigates to Update Password.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/auth_input_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_screen.dart';
import 'auth_service.dart';
import 'sign_up_screen.dart';
import 'update_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signIn(email: email, password: password);
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

  void _goToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _goToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
    );
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome back',
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.primaryStroke,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Good to see you again',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.headingMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Image.asset(
                      'assets/images/rico_splash.png',
                      width: 105,
                      height: 74,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
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
                  trailingHeader: GestureDetector(
                    onTap: _goToForgotPassword,
                    child: Text(
                      'Forgot?',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
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
                const SizedBox(height: AppSpacing.xl),
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
                  label: 'Sign In',
                  onPressed: _isLoading ? null : _signIn,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.m),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      GestureDetector(
                        onTap: _goToSignUp,
                        child: Text(
                          'Sign Up',
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
