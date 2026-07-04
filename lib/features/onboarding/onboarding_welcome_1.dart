// File: lib/features/onboarding/onboarding_welcome_1.dart
// App: Enthusia
// Description: First onboarding screen. Introduces Rico the mascot.
// Tapping anywhere on the screen advances to next onboarding screen.
// Tapping "Skip" jumps directly to Sign In.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/page_dots.dart';
import '../auth/sign_in_screen.dart';
import 'onboarding_welcome_2.dart';

class OnboardingWelcome1 extends StatelessWidget {
  const OnboardingWelcome1({super.key});

  void _goToNext(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingWelcome2()),
    );
  }

  void _goToSignIn(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SignInScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboarding,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _goToNext(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxxl),

                // Rico illustration — centered horizontally
                Center(
                  child: Image.asset(
                    'assets/images/rico_onboarding_1.png',
                    width: 204,
                    height: 145,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  'Meet Rico',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.primaryStroke,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Body text
                Text(
                  'Your stoic penguin coach.\nHe celebrates every win\nand keeps you honest.',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.headingMid,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Page dots — centered horizontally
                const Center(child: PageDots(total: 2, currentIndex: 0)),

                const SizedBox(height: AppSpacing.xl),

                // Skip — centered, close to dots, NO Spacer
                Center(
                  child: GestureDetector(
                    onTap: () => _goToSignIn(context),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
