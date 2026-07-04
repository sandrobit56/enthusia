// File: lib/widgets/bottom_nav.dart
// App: Enthusia
// Description: Bottom navigation bar with Home, Stats, Settings tabs.
// Highlights the active tab with accent color and top border underline.

import 'package:flutter/material.dart';
import '../core/theme/tokens.dart';

enum NavTab { home, stats, settings }

class BottomNav extends StatelessWidget {
  final NavTab activeTab;
  final ValueChanged<NavTab>? onTabSelected;

  const BottomNav({
    super.key,
    required this.activeTab,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: Color(0xFFF7F7F8), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home,
              label: 'Home',
              isActive: activeTab == NavTab.home,
              onTap: () => onTabSelected?.call(NavTab.home),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.bar_chart,
              label: 'Stats',
              isActive: activeTab == NavTab.stats,
              onTap: () => onTabSelected?.call(NavTab.stats),
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.settings,
              label: 'Settings',
              isActive: activeTab == NavTab.settings,
              onTap: () => onTabSelected?.call(NavTab.settings),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: isActive
              ? const Border(
                  top: BorderSide(color: AppColors.accent, width: 1),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.accent : AppColors.muted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.micro.copyWith(
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.accent : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
