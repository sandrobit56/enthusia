// File: lib/core/navigation/nav_helper.dart
// App: Enthusia
// Description: Centralized helper for bottom nav navigation. Avoids
// importing every screen into every screen.

import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/stats/stats_screen.dart';
import '../../widgets/bottom_nav.dart';

void navigateToTab(BuildContext context, NavTab tab) {
  final Widget screen;
  switch (tab) {
    case NavTab.home:
      screen = const HomeScreen();
    case NavTab.stats:
      screen = const StatsScreen();
    case NavTab.settings:
      screen = const SettingsScreen();
  }
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => screen),
  );
}
