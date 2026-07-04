// File: lib/features/auth/update_password_screen.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.25
// Description: Reset password screen. User enters email; Firebase sends a
// password-reset LINK to that address (Firebase-hosted page handles the new
// password). v0.25 removed the fake 4-digit code UI — Firebase's flow has
// no code, and dead UI that promises one is dishonest UX.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/auth_input_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_service.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage =
              'Reset link sent! Check your inbox (and spam folder), then sign in with your new password.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AuthService.describeAuthError(e);
        });
      }
    }
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
                const SizedBox(height: AppSpacing.l),

                // Back pill
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back,
                            size: 16, color: Color(0xFF77777D)),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'back',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF77777D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.l),

                Text(
                  'Reset password',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primaryStroke,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "Enter your email and we'll send you a link to set a new password.",
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.headingMid,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                AuthInputField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: AppSpacing.xl),

                if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.streakBroken,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (_successMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Text(
                      _successMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                PrimaryButton(
                  label: 'Send Reset Link',
                  onPressed: _isLoading ? null : _sendResetLink,
                  isLoading: _isLoading,
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
