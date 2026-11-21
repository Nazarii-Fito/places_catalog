// Named constructor parameters for private fields cannot be initializing
// formals.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../services/crash_reporter.dart';
import 'user_profile_repository.dart';

/// Writes `users/{uid}`: profile fields on every sign-in, `createdAt` only
/// the first time (so it really is the registration time).
class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({
    required FirebaseFirestore firestore,
    required CrashReporter crashReporter,
    this.timeout = const Duration(seconds: 5),
  }) : _db = firestore,
       _crashReporter = crashReporter;

  final FirebaseFirestore _db;
  final CrashReporter _crashReporter;

  /// Without a network the write only completes after reconnecting; the
  /// SDK keeps it queued, so we simply stop waiting.
  final Duration timeout;

  @override
  Future<void> syncProfile(AppUser user) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _db
          .collection('users')
          .doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> current = await ref
          .get()
          .timeout(timeout);
      await ref
          .set({
            ...userProfileFields(user),
            'lastLoginAt': FieldValue.serverTimestamp(),
            if (current.data()?['createdAt'] == null)
              'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(timeout);
    } on TimeoutException {
      // Queued offline; nothing to report.
    } catch (error, stack) {
      await _crashReporter.recordError(
        error,
        stack,
        reason: 'Sync user profile',
      );
    }
  }
}
