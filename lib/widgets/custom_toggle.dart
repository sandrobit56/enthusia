// File: lib/widgets/custom_toggle.dart
// App: Enthusia
// Description: Custom toggle switch matching design system. 44x24px with
// 20x20 thumb. Accent blue when ON, placeholder grey when OFF.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

class CustomToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.accent : AppColors.placeholder,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: value ? AppColors.background : AppColors.onboarding,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
