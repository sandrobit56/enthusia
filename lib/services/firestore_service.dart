// File: lib/services/firestore_service.dart
// App: Enthusia
// Description: Singleton wrapper around Cloud Firestore. Isolates
// Firestore usage from UI screens and TaskService. Provides typed
// methods for user documents and tasks. All operations are scoped
// to the currently signed-in user via FirebaseAuth.instance.currentUser.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/tasks/task.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the current signed-in user's UID, or throws if not signed in.
  String get _currentUid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No signed-in user. Cannot access Firestore.');
    }
    return user.uid;
  }

  /// Reference to the current user's document at users/{uid}.
  DocumentReference<Map<String, dynamic>> get _userDoc {
    return _db.collection('users').doc(_currentUid);
  }

  /// Reference to the current user's tasks subcollection at users/{uid}/tasks.
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    return _userDoc.collection('tasks');
  }

  // ===== User document operations =====

  /// Create the user document for a newly signed-up user.
  /// Called from Sign Up flow after createUserWithEmailAndPassword succeeds.
  /// Idempotent: if doc already exists, this overwrites with current values.
  Future<void> createUserDocument({
    required String username,
    required String email,
  }) async {
    await _userDoc.set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Read the current user's profile data.
  /// Returns null if document doesn't exist.
  Future<Map<String, dynamic>?> getUserDocument() async {
    final snapshot = await _userDoc.get();
    return snapshot.data();
  }

  /// Update specific fields of the user document.
  /// Use this for changing username or other profile data later.
  Future<void> updateUserDocument(Map<String, dynamic> updates) async {
    await _userDoc.update(updates);
  }

  // ===== Task collection reference (used by TaskService later) =====

  /// Public getter for the current user's tasks collection.
  /// TaskService will use this in Prompt 11b for CRUD operations.
  CollectionReference<Map<String, dynamic>> get userTasksCollection =>
      _tasksCollection;

  // ===== Task CRUD =====

  /// Real-time stream of all tasks for the current user.
  /// Emits a new list whenever any task is added/changed/deleted in Firestore.
  /// Tasks are ordered by createdAt descending (newest first).
  Stream<List<Task>> tasksStream() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  /// Add a new task to Firestore. Returns the generated document ID.
  /// The Task object's id field is ignored — Firestore generates a new ID.
  Future<String> addTask(Task task) async {
    final docRef = await _tasksCollection.add(task.toFirestore());
    return docRef.id;
  }

  /// Update an existing task in Firestore.
  /// The task.id must match an existing document.
  Future<void> updateTask(Task task) async {
    await _tasksCollection.doc(task.id).update(task.toFirestore());
  }

  /// Delete a task by its document ID.
  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  // ===== Per-day completion =====

  /// Reference to today's completion document for the current user.
  /// Path: users/{uid}/completions/{YYYY-MM-DD}
  DocumentReference<Map<String, dynamic>> _completionDocForDate(DateTime date) {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return _userDoc.collection('completions').doc(dateKey);
  }

  /// Real-time stream of today's completed task IDs.
  /// Emits an empty set if the doc doesn't exist yet.
  Stream<Set<String>> todayCompletionsStream() {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return _completionDocForDate(todayOnly).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return <String>{};
      final raw = data['tasks'] as List<dynamic>? ?? [];
      return raw.map((id) => id as String).toSet();
    });
  }

  /// Toggle a task's completion state for today. Adds the id if absent, removes if present.
  /// Uses a transaction to avoid race conditions on rapid taps.
  Future<void> toggleTodayCompletion(String taskId) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final docRef = _completionDocForDate(todayOnly);

    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      final current = snapshot.data();
      final existingRaw = current?['tasks'] as List<dynamic>? ?? [];
      final ids = existingRaw.map((id) => id as String).toSet();

      if (ids.contains(taskId)) {
        ids.remove(taskId);
      } else {
        ids.add(taskId);
      }

      tx.set(docRef, {
        'tasks': ids.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Read every completion doc for the current user.
  /// Returns a list of {date: DateTime, taskIds: List<String>} entries
  /// sorted by date ascending. Used by StatsService to compute streaks.
  Future<List<({DateTime date, List<String> taskIds})>> getAllCompletions() async {
    final snapshot = await _userDoc.collection('completions').get();
    final results = <({DateTime date, List<String> taskIds})>[];

    for (final doc in snapshot.docs) {
      // Doc ID is YYYY-MM-DD — parse to DateTime
      final parts = doc.id.split('-');
      if (parts.length != 3) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) continue;

      final date = DateTime(year, month, day);
      final data = doc.data();
      final rawTasks = data['tasks'] as List<dynamic>? ?? [];
      final taskIds = rawTasks.map((id) => id as String).toList();

      results.add((date: date, taskIds: taskIds));
    }

    results.sort((a, b) => a.date.compareTo(b.date));
    return results;
  }

  // ===== Account deletion =====

  /// Delete ALL Firestore data for the current user. Cascades through:
  /// 1. Every task doc in users/{uid}/tasks
  /// 2. Every completion doc in users/{uid}/completions
  /// 3. The user doc at users/{uid}
  /// Must be called BEFORE deleting the FirebaseAuth user (since we need
  /// the UID to find the docs).
  Future<void> deleteAllUserData() async {
    final batch = _db.batch();

    // Delete all tasks
    final tasksSnapshot = await _tasksCollection.get();
    for (final doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete all completions
    final completionsSnapshot =
        await _userDoc.collection('completions').get();
    for (final doc in completionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete user doc itself
    batch.delete(_userDoc);

    await batch.commit();
  }
}
