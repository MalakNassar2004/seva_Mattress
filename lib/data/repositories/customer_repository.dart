import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart'
    show describeError;
import 'package:seva_mattress/modules/customers/customer_models.dart';

/// Thrown when a phone number already belongs to another customer.
/// (Used by the order form, which only checks the phone.)
class PhoneTakenException implements Exception {
  PhoneTakenException(this.phone, this.customerName);

  final String phone;
  final String customerName;

  @override
  String toString() =>
      'The phone $phone already belongs to "$customerName".';
}

/// Thrown when the phone and/or the email already belong to other customers.
/// Both are reported together, so the form can show each error under its own
/// field in one go.
class CustomerConflictException implements Exception {
  CustomerConflictException({this.phoneOwner, this.emailOwner});

  /// Name of the customer who owns the phone (null = the phone is free).
  final String? phoneOwner;

  /// Name of the customer who owns the email (null = the email is free).
  final String? emailOwner;

  bool get phoneTaken => phoneOwner != null;
  bool get emailTaken => emailOwner != null;

  @override
  String toString() => 'Customer conflict: phone=$phoneOwner email=$emailOwner';
}

final RegExp _emailPattern = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');

/// The email in lower case, used as the unique key of an email. Returns null
/// when [raw] is empty or is not a valid email.
/// "Ali@Gmail.com" and "ali@gmail.com" are the same email.
String? normalizeEmail(String raw) {
  final e = raw.trim().toLowerCase();
  if (e.isEmpty || e.length > 120) return null;
  return _emailPattern.hasMatch(e) ? e : null;
}

/// Turns an error into a short message that is safe to show to the user.
String describeCustomerError(Object e) {
  if (e is CustomerConflictException) {
    final parts = <String>[
      if (e.phoneTaken)
        'This phone number is already used by ${e.phoneOwner}.',
      if (e.emailTaken) 'This email is already used by ${e.emailOwner}.',
    ];
    return parts.join(' ');
  }
  if (e is PhoneTakenException) {
    return 'This phone number is already used by ${e.customerName}.';
  }
  if (e is StateError) return e.message;
  return describeError(e);
}

/// All Firestore access for customers.
///
/// Every phone number has its own document in `customer_phones` (the
/// document id is the digits), and every email has one in `customer_emails`
/// (the document id is the email in lower case). Each is created in the same
/// transaction as the customer, so two customers can never share a phone or
/// an email. Every customer also gets the next number (CUST-0001...) from
/// the `customers` counter, in the same transaction.
class CustomerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _db.collection('customers');

  CollectionReference<Map<String, dynamic>> get _phones =>
      _db.collection('customer_phones');

  CollectionReference<Map<String, dynamic>> get _emails =>
      _db.collection('customer_emails');

  CollectionReference<Map<String, dynamic>> get _counters =>
      _db.collection('counters');

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

  Map<String, dynamic> _phoneClaim(String phoneKey, String customerId) => {
    'phone': phoneKey,
    'customerId': customerId,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': _user?.uid,
  };

  Map<String, dynamic> _emailClaim(String emailKey, String customerId) => {
    'email': emailKey,
    'customerId': customerId,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': _user?.uid,
  };

  /// Name of the customer who owns a phone / email claim.
  Future<String> _ownerName(
      Transaction tx,
      Map<String, dynamic>? claim,
      ) async {
    final otherId = claim?['customerId'] as String?;
    if (otherId == null) return 'another customer';
    final other = await tx.get(_customers.doc(otherId));
    final name = (other.data()?['name'] as String?) ?? '';
    return name.isEmpty ? 'another customer' : name;
  }

  /// The key of the email, null when there is no email. Throws when the
  /// email is not valid.
  String? _emailKeyOf(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;
    final key = normalizeEmail(trimmed);
    if (key == null) throw StateError('This email address is not valid.');
    return key;
  }

  /// Creates a customer with id [id] ([phoneKey] = the digits).
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
      throw StateError('This phone number is not valid.');
    }
    final emailKey = _emailKeyOf(email);

    final ref = _customers.doc(id);
    final data = _fields(
      name: name,
      phoneKey: phoneKey,
      email: email,
      city: city,
      address: address,
      notes: notes,
    );
    String? number;

    await _db.runTransaction((tx) async {
      // ---------- reads ----------
      final existing = await tx.get(ref);
      if (existing.exists) {
        // A retry of a save that already went through.
        number = existing.data()?['number'] as String?;
        return;
      }

      final counterRef = _counters.doc('customers');
      final counter = await tx.get(counterRef);
      final seq = ((counter.data()?['last'] as num?)?.toInt() ?? 0) + 1;

      // Phone and email are both checked, then reported together.
      final phoneRef = _phones.doc(phoneKey);
      final phoneClaim = await tx.get(phoneRef);
      String? phoneOwner;
      if (phoneClaim.exists) {
        phoneOwner = await _ownerName(tx, phoneClaim.data());
      }

      DocumentReference<Map<String, dynamic>>? emailRef;
      String? emailOwner;
      if (emailKey != null) {
        emailRef = _emails.doc(emailKey);
        final emailClaim = await tx.get(emailRef);
        if (emailClaim.exists) {
          emailOwner = await _ownerName(tx, emailClaim.data());
        }
      }

      if (phoneOwner != null || emailOwner != null) {
        throw CustomerConflictException(
          phoneOwner: phoneOwner,
          emailOwner: emailOwner,
        );
      }

      // ---------- writes ----------
      final customerNumber = customerNumberOf(seq);
      number = customerNumber;

      if (counter.exists) {
        tx.update(counterRef, {'last': seq});
      } else {
        tx.set(counterRef, {'last': seq});
      }
      tx.set(ref, {
        ...data,
        'number': customerNumber,
        'seq': seq,
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _user?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });
      tx.set(phoneRef, _phoneClaim(phoneKey, id));
      if (emailRef != null && emailKey != null) {
        tx.set(emailRef, _emailClaim(emailKey, id));
      }
      tx.set(
        _audit.doc(),
        _auditEntry(
          type: 'customer_created',
          customerId: id,
          customerName: name,
          details: {'phone': phoneKey, 'number': customerNumber},
        ),
      );
    });

    return customerFromMap(
      id,
      {...data, 'number': number ?? ''},
      createdAt: DateTime.now(),
    );
  }

  /// Updates a customer. Changed fields are written to the audit log. A
  /// customer saved before numbers existed gets his number now.
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
      throw StateError('This phone number is not valid.');
    }
    final emailKey = _emailKeyOf(email);

    final ref = _customers.doc(id);
    final data = _fields(
      name: name,
      phoneKey: phoneKey,
      email: email,
      city: city,
      address: address,
      notes: notes,
    );
    String? number;

    await _db.runTransaction((tx) async {
      // ---------- reads ----------
      final snap = await tx.get(ref);
      final old = snap.data();
      if (!snap.exists || old == null || old['deleted'] == true) {
        throw StateError('This customer no longer exists.');
      }
      final o = old;

      // Number: only a customer without one gets the next number.
      final oldNumber = (o['number'] as String?) ?? '';
      final counterRef = _counters.doc('customers');
      DocumentSnapshot<Map<String, dynamic>>? counter;
      int? newSeq;
      if (oldNumber.isEmpty) {
        counter = await tx.get(counterRef);
        newSeq = ((counter.data()?['last'] as num?)?.toInt() ?? 0) + 1;
      }

      // Phone.
      final oldKey = (o['phone'] as String?) ?? '';
      final keyChanged = oldKey != phoneKey;

      final newPhoneRef = _phones.doc(phoneKey);
      final newPhoneClaim = await tx.get(newPhoneRef);
      String? phoneOwner;
      if (newPhoneClaim.exists && newPhoneClaim.data()?['customerId'] != id) {
        phoneOwner = await _ownerName(tx, newPhoneClaim.data());
      }

      // Email. A customer saved before emails were reserved has no claim yet:
      // it is created now.
      DocumentReference<Map<String, dynamic>>? newEmailRef;
      DocumentSnapshot<Map<String, dynamic>>? newEmailClaim;
      String? emailOwner;
      if (emailKey != null) {
        newEmailRef = _emails.doc(emailKey);
        newEmailClaim = await tx.get(newEmailRef);
        if (newEmailClaim.exists && newEmailClaim.data()?['customerId'] != id) {
          emailOwner = await _ownerName(tx, newEmailClaim.data());
        }
      }

      // Phone and email are both checked, then reported together.
      if (phoneOwner != null || emailOwner != null) {
        throw CustomerConflictException(
          phoneOwner: phoneOwner,
          emailOwner: emailOwner,
        );
      }

      DocumentSnapshot<Map<String, dynamic>>? oldPhoneClaim;
      if (keyChanged && normalizePhone(oldKey) == oldKey) {
        oldPhoneClaim = await tx.get(_phones.doc(oldKey));
      }

      final oldEmailKey = normalizeEmail((o['email'] as String?) ?? '');
      DocumentSnapshot<Map<String, dynamic>>? oldEmailClaim;
      if (oldEmailKey != null && oldEmailKey != emailKey) {
        oldEmailClaim = await tx.get(_emails.doc(oldEmailKey));
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

      // ---------- writes ----------
      final String assigned =
      newSeq == null ? oldNumber : customerNumberOf(newSeq);
      number = assigned;

      if (counter != null && newSeq != null) {
        if (counter.exists) {
          tx.update(counterRef, {'last': newSeq});
        } else {
          tx.set(counterRef, {'last': newSeq});
        }
      }

      tx.update(ref, {
        ...data,
        if (newSeq != null) ...{'number': assigned, 'seq': newSeq},
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _user?.uid,
      });

      // A new phone, or a customer saved before phones were reserved.
      if (!newPhoneClaim.exists) {
        tx.set(newPhoneRef, _phoneClaim(phoneKey, id));
      }
      // The old phone becomes free for other customers.
      if (oldPhoneClaim != null &&
          oldPhoneClaim.exists &&
          oldPhoneClaim.data()?['customerId'] == id) {
        tx.delete(oldPhoneClaim.reference);
      }

      // A new email, or a customer saved before emails were reserved.
      if (newEmailRef != null &&
          emailKey != null &&
          newEmailClaim != null &&
          !newEmailClaim.exists) {
        tx.set(newEmailRef, _emailClaim(emailKey, id));
      }
      // The old email becomes free for other customers.
      if (oldEmailClaim != null &&
          oldEmailClaim.exists &&
          oldEmailClaim.data()?['customerId'] == id) {
        tx.delete(oldEmailClaim.reference);
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

    return customerFromMap(id, {...data, 'number': number ?? ''});
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