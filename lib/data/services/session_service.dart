import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The signed-in employee, read from the `users` collection.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final bool active;

  bool get isOwner => active && role == 'owner';
  bool get isManager => active && role == 'manager';
}

class SessionService {
  /// Returns null when nobody is signed in or the account has no employee
  /// profile. Throws a FirebaseException if the profile cannot be read
  /// (for example no connection): callers must handle it.
  Future<AppUser?> loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final m = doc.data();
    if (!doc.exists || m == null) return null;

    return AppUser(
      uid: user.uid,
      name: (m['name'] as String?)?.trim() ?? '',
      email: (m['email'] as String?) ?? '',
      role: (m['role'] as String?) ?? '',
      active: m['active'] == true,
    );
  }
}