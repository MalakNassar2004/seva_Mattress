import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart'
    show describeError;
import 'package:seva_mattress/modules/customers/customer_models.dart';

/// Thrown when a phone number already belongs to another customer.
class PhoneTakenException implements Exception {
  PhoneTakenException(this.phone, this.customerName);

  final String phone;
  final String customerName;

  @override
  String toString() =>
      'The phone $phone already belongs to "$customerName".';
}

/// Turns an error into a short message that is safe to show to the user.
String describeCustomerError(Object e) {
  if (e is PhoneTakenException) {
    return 'This phone number already belongs to ${e.customerName}.';
  }
  return describeError(e);
}

/// All Firestore access for customers.
///
/// Every phone number has its own document in `customer_phones` (the
/// document id is the 10 digits). It is created in the same transaction as
/// the customer, so two customers can never share a phone.
class CustomerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _db.collection('customers');

  CollectionReference<Map<String, dynamic>> get _phones =>
      _db.collection('customer_phones');

  CollectionReference<Map<String, dynamic>> get _audit =>
      _db.collection('audit_log');

  User? get _user => FirebaseAuth.instance.currentUser;

  /// A new customer id. The form creates it ONCE, so pressing Save twice (or
  /// retrying on a bad connection) can never create two customers.
  String newId() => _customers.doc().id;

  /// Live list of customers.
  Stream<List<CustomerItem>> watchCustomers() {
    return _customers.snapshots().map(
          (snap) => snap.docs
          .where((d) => d.data()['deleted'] != true)
          .map(
            (d) => customerFromMap(
          d.id,
          d.data(),
          createdAt: (d.data()['createdAt'] as Timestamp?)?.toDate(),
        ),
      )
          .toList(),
    );
  }

  /// Live data of one customer (null when it does not exist).
  Stream<CustomerItem?> watchCustomer(String id) {
    return _customers.doc(id).snapshots().map((snap) {
      final m = snap.data();
      if (!snap.exists || m == null || m['deleted'] == true) return null;
      return customerFromMap(
        snap.id,
        m,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  /// The customer who owns this phone number, or null.
  Future<CustomerItem?> findByPhone(String rawPhone) async {
    final key = normalizePhone(rawPhone);
    if (key == null) return null;

    final claim = await _phones.doc(key).get();
    final customerId = claim.data()?['customerId'] as String?;
    if (!claim.exists || customerId == null) return null;

    final snap = await _customers.doc(customerId).get();
    final m = snap.data();
    if (!snap.exists || m == null || m['deleted'] == true) return null;
    return customerFromMap(
      snap.id,
      m,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _fields({
    required String name,
    required String phoneKey,
    required String email,
    required String city,
    required String address,
    required String notes,
  }) {
    return {
      'name': name,
      'nameLower': name.toLowerCase(),
      'phone': phoneKey,
      'email': email,
      'city': city,
      'address': address,
      'notes': notes,
    };
  }

  Map<String, dynamic> _claim(String phoneKey, String customerId) => {
    'phone': phoneKey,
    'customerId': customerId,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': _user?.uid,
  };

  Future<PhoneTakenException> _takenBy(
      Transaction tx,
      String phoneKey,
      Map<String, dynamic>? claim,
      ) async {
    final otherId = claim?['customerId'] as String?;
    var name = '';
    if (otherId != null) {
      final other = await tx.get(_customers.doc(otherId));
      name = (other.data()?['name'] as String?) ?? '';
    }
    return PhoneTakenException(
      formatPhone(phoneKey),
      name.isEmpty ? 'another customer' : name,
    );
  }

  /// Creates a customer with id [id] ([phoneKey] = the 10 digits).
  Future<CustomerItem> create(
      String id, {
        required String name,
        required String phoneKey,
        String email = '',
        String city = '',
        String address = '',
        String notes = '',
      }) async {
    if (normalizePhone(phoneKey) != phoneKey) {
      throw StateError('Enter a valid 10-digit phone number.');
    }

    final ref = _customers.doc(id);
    final data = _fields(
      name: name,
      phoneKey: phoneKey,
      email: email,
      city: city,
      address: address,
      notes: notes,
    );

    await _db.runTransaction((tx) async {
      // All reads first.
      final existing = await tx.get(ref);
      if (existing.exists) return; // a retry of a save that already went through

      final claimRef = _phones.doc(phoneKey);
      final claim = await tx.get(claimRef);
      if (claim.exists) throw await _takenBy(tx, phoneKey, claim.data());

      // Then the writes.
      tx.set(ref, {
        ...data,
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _user?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });
      tx.set(claimRef, _claim(phoneKey, id));
      tx.set(
        _audit.doc(),
        _auditEntry(
          type: 'customer_created',
          customerId: id,
          customerName: name,
          details: {'phone': phoneKey},
        ),
      );
    });

    return customerFromMap(id, data, createdAt: DateTime.now());
  }

  /// Updates a customer. Changed fields are written to the audit log.
  Future<CustomerItem> update(
      String id, {
        required String name,
        required String phoneKey,
        String email = '',
        String city = '',
        String address = '',
        String notes = '',
      }) async {
    if (normalizePhone(phoneKey) != phoneKey) {
      throw StateError('Enter a valid 10-digit phone number.');
    }

    final ref = _customers.doc(id);
    final data = _fields(
      name: name,
      phoneKey: phoneKey,
      email: email,
      city: city,
      address: address,
      notes: notes,
    );

    await _db.runTransaction((tx) async {
      // All reads first.
      final snap = await tx.get(ref);
      final old = snap.data();
      if (!snap.exists || old == null || old['deleted'] == true) {
        throw StateError('This customer no longer exists.');
      }
      final o = old;

      final oldKey = (o['phone'] as String?) ?? '';
      final keyChanged = oldKey != phoneKey;

      final newClaimRef = _phones.doc(phoneKey);
      final newClaim = await tx.get(newClaimRef);
      if (newClaim.exists && newClaim.data()?['customerId'] != id) {
        throw await _takenBy(tx, phoneKey, newClaim.data());
      }

      DocumentSnapshot<Map<String, dynamic>>? oldClaim;
      if (keyChanged && normalizePhone(oldKey) == oldKey) {
        oldClaim = await tx.get(_phones.doc(oldKey));
      }

      // What changed (for the audit log).
      final changes = <String, dynamic>{};
      void diff(String field, Object? to) {
        final from = o[field];
        if ((from ?? '') != (to ?? '')) {
          changes[field] = {'from': from, 'to': to};
        }
      }

      diff('name', name);
      diff('phone', phoneKey);
      diff('email', email);
      diff('city', city);
      diff('address', address);
      diff('notes', notes);

      // Then the writes.
      tx.update(ref, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });

      // A new phone, or a customer saved before phones were reserved.
      if (!newClaim.exists) {
        tx.set(newClaimRef, _claim(phoneKey, id));
      }
      // The old phone becomes free for other customers.
      if (oldClaim != null &&
          oldClaim.exists &&
          oldClaim.data()?['customerId'] == id) {
        tx.delete(oldClaim.reference);
      }

      if (changes.isNotEmpty) {
        tx.set(
          _audit.doc(),
          _auditEntry(
            type: 'customer_updated',
            customerId: id,
            customerName: name,
            details: changes,
          ),
        );
      }
    });

    return customerFromMap(id, data);
  }

  Map<String, dynamic> _auditEntry({
    required String type,
    required String customerId,
    required String customerName,
    required Map<String, dynamic> details,
  }) {
    return {
      'type': type,
      'customerId': customerId,
      'customerName': customerName,
      'details': details,
      'actorUid': _user?.uid,
      'actorEmail': _user?.email,
      'at': FieldValue.serverTimestamp(),
    };
  }
}