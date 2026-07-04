// File: lib/features/splash/splash_screen.dart
// App: Enthusia
// Description: First screen the user sees. Shows Rico, app name,
// and tagline on a blue background. Auto-advances to onboarding after
// 1.5 seconds.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_welcome_1.dart';

/// Splash screen with Rico mascot, app name, and tagline.
/// Layout matches Figma: page/splash node.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Returning signed-in user → skip onboarding, go directly to Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // First-time or signed-out user → show onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingWelcome1()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rico mascot
            Image.asset(
              'assets/images/rico_splash.png',
              width: 184,
              height: 148,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: AppSpacing.m),

            // App name
            Text(
              'Enthusia',
              style: AppTextStyles.h1.copyWith(color: AppColors.onPrimary),
            ),

            const SizedBox(height: AppSpacing.s),

            // Tagline pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Build habits. Stay consistent.',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
