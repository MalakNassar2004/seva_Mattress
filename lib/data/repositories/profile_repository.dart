import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;

/// The signed-in employee's own profile.
class MyProfile {
  const MyProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
  });

  final String name;
  final String phone;
  final String email;
  final String role;
}

/// A readable message for the errors of the profile screens.
String describeProfileError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'requires-recent-login':
        return 'For security, enter your current password to confirm.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'The password is not correct.';
      case 'email-already-in-use':
        return 'This email is already used by another account.';
      case 'invalid-email':
        return 'This email address is not valid.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'No connection. Check the internet and try again.';
      default:
        return e.message ?? 'Something went wrong. Try again.';
    }
  }
  return describeCustomerError(e);
}

/// The employee edits his OWN profile here: name, phone and sign-in email.
/// The role and the active flag can never be changed from the app.
class ProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  User _me() {
    final u = _auth.currentUser;
    if (u == null) throw StateError('You are not signed in.');
    return u;
  }

  /// Live data of one employee document.
  Stream<Map<String, dynamic>?> watchDoc(String uid) =>
      _users.doc(uid).snapshots().map((s) => s.data());

  Future<MyProfile> loadMine() async {
    final u = _me();
    final snap = await _users.doc(u.uid).get();
    final m = snap.data();
    if (!snap.exists || m == null) {
      throw StateError('Your employee profile was not found.');
    }
    return MyProfile(
      name: ((m['name'] as String?) ?? '').trim(),
      phone: (m['phone'] as String?) ?? '',
      email: u.email ?? (m['email'] as String?) ?? '',
      role: (m['role'] as String?) ?? '',
    );
  }

  /// Saves the name and the phone. What changed goes to the audit log.
  Future<void> saveNamePhone({
    required String name,
    required String phone,
  }) async {
    final u = _me();
    final ref = _users.doc(u.uid);
    final snap = await ref.get();
    final o = snap.data() ?? <String, dynamic>{};

    final oldName = ((o['name'] as String?) ?? '').trim();
    final oldPhone = (o['phone'] as String?) ?? '';
    final changes = <String, dynamic>{};
    if (oldName != name) changes['name'] = {'from': oldName, 'to': name};
    if (oldPhone != phone) changes['phone'] = {'from': oldPhone, 'to': phone};
    if (changes.isEmpty) return;

    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();
    batch.update(ref, {'name': name, 'phone': phone, 'updatedAt': now});
    batch.set(_db.collection('audit_log').doc(), {
      'type': 'profile_updated',
      'details': changes,
      'actorUid': u.uid,
      'actorEmail': u.email,
      'at': now,
    });
    await batch.commit();
  }

  /// Asks to change the sign-in email: a confirmation link is sent to the NEW
  /// address, and the email changes when it is opened. When Firebase wants a
  /// recent sign-in, the current [password] is used to confirm.
  Future<void> requestEmailChange({
    required String newEmail,
    String? password,
  }) async {
    final u = _me();
    final oldEmail = u.email ?? '';
    if (password != null && password.isNotEmpty) {
      await u.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: oldEmail, password: password),
      );
    }
    await u.verifyBeforeUpdateEmail(newEmail);
    try {
      await _db.collection('audit_log').add({
        'type': 'profile_email_requested',
        'details': {
          'email': {'from': oldEmail, 'to': newEmail},
        },
        'actorUid': u.uid,
        'actorEmail': oldEmail,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // The email request was sent; the log entry is not essential.
    }
  }

  Future<void> sendPasswordReset() async {
    final u = _me();
    final email = u.email;
    if (email == null || email.isEmpty) {
      throw StateError('Your account has no email.');
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// After the new email was confirmed, copies it to the employee document.
  /// Silent: if it cannot be done now, it is tried on the next app start.
  Future<void> syncEmail() async {
    try {
      final current = _auth.currentUser;
      if (current == null) return;
      await current.reload();
      final u = _auth.currentUser;
      final email = u?.email;
      if (u == null || email == null || email.isEmpty) return;
      await u.getIdToken(true); // so the rules see the new email

      final ref = _users.doc(u.uid);
      final snap = await ref.get();
      final docEmail = ((snap.data()?['email'] as String?) ?? '').trim();
      if (!snap.exists || docEmail.toLowerCase() == email.toLowerCase()) {
        return;
      }
      await ref.update({
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}