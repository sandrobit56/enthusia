// File: lib/services/user_service.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.27
// Description: Singleton service that holds the current user's profile
// data (username, email). Auto-loads from Firestore on sign-in, clears
// on sign-out. UI widgets use AnimatedBuilder(animation: UserService.instance)
// to rebuild when profile changes. v0.26 adds reload() for post-edit
// refresh. v0.27 silently heals the stale Firestore email copy after a
// verified email change (Auth is the source of truth).

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

class UserService extends ChangeNotifier {
  UserService._() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadProfile();
      } else {
        _clearProfile();
      }
    });
  }

  static final UserService instance = UserService._();

  String? _username;
  String? _email;
  bool _isLoading = false;

  StreamSubscription<User?>? _authSubscription;

  /// Username from Firestore user doc. Null while loading or if not signed in.
  String? get username => _username;

  /// Email from FirebaseAuth current user. Null if not signed in.
  String? get email => _email;

  bool get isLoading => _isLoading;

  /// First letter of username (uppercase). Falls back to first letter of email,
  /// or "?" if neither available. Used for avatar circles.
  String get avatarLetter {
    if (_username != null && _username!.isNotEmpty) {
      return _username!.substring(0, 1).toUpperCase();
    }
    if (_email != null && _email!.isNotEmpty) {
      return _email!.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  Future<void> _loadProfile() async {
    _isLoading = true;
    _email = FirebaseAuth.instance.currentUser?.email;
    notifyListeners();

    try {
      final data = await FirestoreService.instance.getUserDocument();
      _username = data?['username'] as String?;

      final firestoreEmail = data?['email'] as String?;
      if (_email != null && firestoreEmail != _email) {
        // Auth is the source of truth for email; heal the Firestore copy
        // silently (it goes stale after a verified email change).
        await FirestoreService.instance.updateUserDocument({'email': _email});
      }
    } catch (e) {
      debugPrint('UserService load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Re-fetch the profile from Firestore. Call after editing profile data
  /// (e.g. username change) so UI listening to this service updates.
  Future<void> reload() => _loadProfile();

  void _clearProfile() {
    _username = null;
    _email = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
