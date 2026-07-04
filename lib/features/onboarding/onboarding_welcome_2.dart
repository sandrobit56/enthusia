// File: lib/features/onboarding/onboarding_welcome_2.dart
// App: Enthusia
// Description: Second onboarding screen. Shows green check badge,
// "Easy to manage" message, and a "Let's Go" primary button that
// advances to Sign In.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../widgets/page_dots.dart';
import '../../widgets/primary_button.dart';
import '../auth/sign_in_screen.dart';

class OnboardingWelcome2 extends StatelessWidget {
  const OnboardingWelcome2({super.key});

  void _goToHome(BuildContext context) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Green check badge
              Container(
                width: 114,
                height: 101,
                decoration: BoxDecoration(
                  color: AppColors.checkBadge,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.checkBadgeBorder,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check,
                  color: AppColors.onPrimary,
                  size: 48,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title + body, left-aligned
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Easy to manage',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primaryStroke,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'check your habits and track\ncalendar, manage your day',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.headingMid,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Page dots — second dot active
              const PageDots(total: 2, currentIndex: 1),

              const Spacer(),

              // Let's Go button
              PrimaryButton(
                label: "Let's Go",
                onPressed: () => _goToHome(context),
              ),

              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }
}
