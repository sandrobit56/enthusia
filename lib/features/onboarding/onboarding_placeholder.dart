// File: lib/features/onboarding/onboarding_placeholder.dart
// App: Enthusia
// Description: Temporary placeholder for not-yet-built screens.
// Replaced by real screens as the app grows. Helps us build navigation
// before all screens exist.

import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';

class PlaceholderScreen extends StatelessWidget {
  final String label;
  const PlaceholderScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Placeholder: $label', style: AppTextStyles.h2)),
    );
  }
}
