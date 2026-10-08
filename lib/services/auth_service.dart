// ignore_for_file: prefer_initializing_formals
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import 'local_prefs.dart';

/// Authentication abstraction.
///
/// Uses Firebase Authentication when Firebase is configured; otherwise
/// falls back to a clearly-labeled local demo account so the app remains
/// runnable and demonstrable without credentials.
class AuthService {
  final bool firebaseAvailable;
  final LocalPrefs prefs;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  AuthService({
    required this.firebaseAvailable,
    required this.prefs,
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth,
        _db = db;

  Stream<AppUser?> authState() {
    if (firebaseAvailable && _auth != null) {
      return _auth.authStateChanges().asyncMap((u) async {
        if (u == null) return null;
        final name = u.displayName ?? await _fetchName(u.uid) ?? 'User';
        return AppUser(uid: u.uid, name: name, email: u.email ?? '');
      });
    }
    // Local mode: single stream snapshot.
    return Stream.value(currentUser());
  }

  AppUser? currentUser() {
    if (firebaseAvailable && _auth != null) {
      final u = _auth.currentUser;
      if (u == null) return null;
      return AppUser(
          uid: u.uid, name: u.displayName ?? 'User', email: u.email ?? '');
    }
    final id = prefs.demoUserId;
    if (id == null) return null;
    return AppUser(
        uid: id, name: prefs.demoUserName, email: prefs.demoUserEmail);
  }

  Future<AppUser> signIn(String email, String password) async {
    if (firebaseAvailable && _auth != null) {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      final u = cred.user!;
      final name = u.displayName ?? await _fetchName(u.uid) ?? 'User';
      return AppUser(uid: u.uid, name: name, email: u.email ?? '');
    }
    // Local demo: accept any previously registered demo account.
    final id = prefs.demoUserId;
    if (id == null || prefs.demoUserEmail != email.trim()) {
      throw Exception('No local account found for that email. '
          'Please register first (local demo mode).');
    }
    return AppUser(uid: id, name: prefs.demoUserName, email: email.trim());
  }

  Future<AppUser> register(
      {required String name,
      required String email,
      required String password}) async {
    if (firebaseAvailable && _auth != null) {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user!.updateDisplayName(name.trim());
      await _db
          ?.collection('users')
          .doc(cred.user!.uid)
          .set({
            'name': name.trim(),
            'email': email.trim(),
            'currency': prefs.currency,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .catchError((_) {});
      return AppUser(
          uid: cred.user!.uid, name: name.trim(), email: email.trim());
    }
    final uid = 'local_${const Uuid().v4()}';
    await prefs.setDemoUser(
        uid: uid, name: name.trim(), email: email.trim());
    return AppUser(uid: uid, name: name.trim(), email: email.trim());
  }

  Future<void> sendPasswordReset(String email) async {
    if (firebaseAvailable && _auth != null) {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return;
    }
    // Local mode has no email delivery; surface a clear message.
    throw Exception(
        'Password reset email is unavailable in local demo mode. '
        'Connect Firebase to enable it.');
  }

  Future<void> signOut() async {
    if (firebaseAvailable && _auth != null) {
      await _auth.signOut();
    } else {
      // Keep the demo account but sign out of the session marker.
      await prefs.clearDemoUser();
    }
  }

  Future<String?> _fetchName(String uid) async {
    try {
      final doc = await _db?.collection('users').doc(uid).get();
      return doc?.data()?['name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
