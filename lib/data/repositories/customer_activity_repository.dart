import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/modules/orders/order_models.dart';

/// One after-sales note of a customer.
class CustomerNote {
  const CustomerNote({
    required this.id,
    required this.text,
    required this.by,
    required this.at,
  });

  final String id;
  final String text;

  /// Email of the employee who wrote it.
  final String by;
  final DateTime at;
}

/// What happened with one customer: his orders and his notes.
class CustomerActivityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _notes(String customerId) =>
      _db.collection('customers').doc(customerId).collection('notes');

  /// The orders of this customer, newest first.
  /// (Sorted here, so Firestore does not need an extra index.)
  Stream<List<OrderItem>> watchOrders(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snap) {
      final rows = snap.docs.map((d) {
        final m = d.data();
        final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return (at, orderItemFromMap(d.id, m, at));
      }).toList();
      rows.sort((a, b) => b.$1.compareTo(a.$1));
      return [for (final r in rows) r.$2];
    });
  }

  /// The notes of this customer, newest first.
  Stream<List<CustomerNote>> watchNotes(String customerId) {
    return _notes(customerId).snapshots().map((snap) {
      final list = snap.docs.map((d) {
        final m = d.data();
        return CustomerNote(
          id: d.id,
          text: (m['text'] as String?) ?? '',
          by: (m['by'] as String?) ?? '',
          at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      list.sort((a, b) => b.at.compareTo(a.at));
      return list;
    });
  }

  /// A new note id. The sheet creates it ONCE, so a double tap on Save (or a
  /// retry on a bad connection) can never save the same note twice.
  String newNoteId(String customerId) => _notes(customerId).doc().id;

  /// Adds a note (it can never be edited or deleted afterwards).
  Future<void> addNote({
    required String customerId,
    required String customerName,
    required String noteId,
    required String text,
  }) async {
    final ref = _notes(customerId).doc(noteId);

    await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) return; // a retry that already went through

      tx.set(ref, {
        'text': text,
        'by': _user?.email ?? '',
        'at': FieldValue.serverTimestamp(),
        'createdBy': _user?.uid,
      });
      tx.set(_db.collection('audit_log').doc(), {
        'type': 'customer_note',
        'customerId': customerId,
        'customerName': customerName,
        'details': {'length': text.length},
        'actorUid': _user?.uid,
        'actorEmail': _user?.email,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }
}