import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/data/services/notification_types.dart';

/// Which notifications are on. They live in the Firestore document
/// settings/notifications, in a list of ids. If the document does not exist,
/// everything is on.
class NotificationPrefsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('settings').doc('notifications');

  User? get _user => FirebaseAuth.instance.currentUser;

  Set<String> _parse(Map<String, dynamic>? data) {
    final v = data?['on'];
    final ids = v is List
        ? v.whereType<String>().toSet()
        : NotificationTypes.allIds.toSet();
    return {
      for (final t in NotificationTypes.all)
        if (ids.contains(t.id)) t.id,
    };
  }

  Set<String> _read(Map<String, dynamic>? data) {
    final on = _parse(data);
    NotificationTypes.apply(on);
    return on;
  }

  /// For the edit sheet: a read error is thrown, so the defaults are never
  /// saved over real data by mistake.
  Future<Set<String>> loadStrict() async {
    final snap = await _doc.get();
    return _read(snap.data());
  }

  /// Live list of the ids that are on.
  Stream<Set<String>> watch() => _doc.snapshots().map((s) => _read(s.data()));

  /// Saves the list. What was turned on or off goes to the audit log.
  Future<void> save(Set<String> on) async {
    final list = [
      for (final t in NotificationTypes.all)
        if (on.contains(t.id)) t.id,
    ];

    await _db.runTransaction((tx) async {
      final snap = await tx.get(_doc);
      final old = _parse(snap.data());
      final next = list.toSet();

      final turnedOn = next.difference(old).toList()..sort();
      final turnedOff = old.difference(next).toList()..sort();
      if (turnedOn.isEmpty && turnedOff.isEmpty) return;

      tx.set(_doc, {'on': list});
      tx.set(_db.collection('audit_log').doc(), {
        'type': 'settings_updated',
        'details': {
          if (turnedOn.isNotEmpty) 'notificationsOn': turnedOn.join(', '),
          if (turnedOff.isNotEmpty) 'notificationsOff': turnedOff.join(', '),
        },
        'actorUid': _user?.uid,
        'actorEmail': _user?.email,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }
}