import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/modules/settings/settings_store.dart'
    show ApprovalRules;

/// The approval rules of the store. They live in the Firestore document
/// settings/approvals, so they are the same on every phone and they stay
/// after the app is closed. If the document does not exist, the defaults
/// are used.
class ApprovalRulesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('settings').doc('approvals');

  User? get _user => FirebaseAuth.instance.currentUser;

  ApprovalRules _parse(Map<String, dynamic>? m) {
    const d = ApprovalRules.defaults;
    if (m == null) return d;

    bool pickBool(String key, bool fallback) {
      final v = m[key];
      return v is bool ? v : fallback;
    }

    final cents = (m['refundLimitCents'] as num?)?.toInt();
    final discount = (m['maxCashierDiscount'] as num?)?.toInt();

    return ApprovalRules(
      refundLimit: cents == null ? d.refundLimit : cents / 100,
      maxCashierDiscount: discount == null
          ? d.maxCashierDiscount
          : discount.clamp(0, 100).toInt(),
      priceChangeApproval:
          pickBool('priceChangeApproval', d.priceChangeApproval),
      voidApproval: pickBool('voidApproval', d.voidApproval),
      managerSelfApproval:
          pickBool('managerSelfApproval', d.managerSelfApproval),
    );
  }

  Map<String, dynamic> _toMap(ApprovalRules r) => {
    'refundLimitCents': (r.refundLimit * 100).round(),
    'maxCashierDiscount': r.maxCashierDiscount,
    'priceChangeApproval': r.priceChangeApproval,
    'voidApproval': r.voidApproval,
    'managerSelfApproval': r.managerSelfApproval,
  };

  /// Readable name and value of a field, for the audit log.
  (String, Object) _show(String key, Object? v) {
    switch (key) {
      case 'refundLimitCents':
        final cents = (v as num?)?.toInt() ?? 0;
        return ('refundLimit', '\$${(cents / 100).toStringAsFixed(0)}');
      case 'maxCashierDiscount':
        return ('maxCashierDiscount', '$v%');
      default:
        return (key, v == true ? 'on' : 'off');
    }
  }

  /// Live rules.
  Stream<ApprovalRules> watch() =>
      _doc.snapshots().map((s) => _parse(s.data()));

  /// For the edit screen: a read error is thrown, so the defaults are never
  /// saved over real rules by mistake.
  Future<ApprovalRules> loadStrict() async {
    final snap = await _doc.get();
    return _parse(snap.data());
  }

  /// Saves the rules. What changed is written to the audit log.
  Future<void> save(ApprovalRules rules) async {
    final next = _toMap(rules);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(_doc);
      final old = _toMap(_parse(snap.data()));

      final changes = <String, dynamic>{};
      next.forEach((key, value) {
        if (old[key] != value) {
          final (name, from) = _show(key, old[key]);
          final (_, to) = _show(key, value);
          changes[name] = {'from': from, 'to': to};
        }
      });
      if (changes.isEmpty) return;

      tx.set(_doc, next);
      tx.set(_db.collection('audit_log').doc(), {
        'type': 'settings_updated',
        'details': changes,
        'actorUid': _user?.uid,
        'actorEmail': _user?.email,
        'at': FieldValue.serverTimestamp(),
      });
    });
  }
}