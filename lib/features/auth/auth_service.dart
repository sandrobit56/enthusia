// File: lib/features/auth/auth_service.dart
// App: Enthusia
// Author: Sandro
// Date: 2026-07-04
// Version: 0.27
// Description: Singleton wrapper around FirebaseAuth. Isolates Firebase
// usage from UI screens. Provides sign up, sign in, sign out, auth state
// stream, reauth, account deletion, verified email change (v0.27), and a
// static helper to translate auth errors to user-friendly messages.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes. AuthGate listens to this and routes
  /// the user to Home or Sign In automatically.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Create a new account with email and password.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in an existing user with email and password.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email to a given address.
  /// Throws FirebaseAuthException on failure.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Re-authenticate the current user with email + password.
  /// Required before deleteAccount() if it's been >5 min since last sign-in.
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('No signed-in user to reauthenticate.');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Send a verification link to [newEmail]. When the user clicks it,
  /// Firebase updates their sign-in email and revokes the current session
  /// (security policy) — they must sign in again with the new address.
  /// Requires recent login: call reauthenticateWithPassword first.
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  /// Delete the current FirebaseAuth user. Throws if recent-login required.
  /// IMPORTANT: caller must delete Firestore data BEFORE calling this, since
  /// we lose the UID once the auth user is gone.
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user to delete.');
    }
    await user.delete();
  }

  /// Translate auth errors into user-friendly messages.
  /// UI screens call this in catch blocks to show clean errors.
  static String describeAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Password is too weak. Use at least 8 characters.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Email address is not valid.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'too-many-requests':
          return 'Too many attempts. Try again in a few minutes.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
