import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seva_mattress/app/utils/money.dart';
import 'package:seva_mattress/app/utils/names.dart';
import 'package:seva_mattress/modules/audit/audit_models.dart';
import 'package:seva_mattress/modules/customers/customer_models.dart'
    show formatPhone;
import 'package:seva_mattress/modules/orders/order_models.dart'
    show OrderStatusStyle, orderStatusFrom;

class _Person {
  const _Person(this.name, this.role);

  final String name;
  final String role;
}

class _Described {
  const _Described(this.sentence, {this.oldValue, this.newValue, this.note});

  final String sentence;
  final String? oldValue;
  final String? newValue;
  final String? note;
}

/// Reads the audit log (only the owner is allowed to read it). Every other
/// repository writes into it; nobody can edit or delete an entry.
class AuditRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Live list, newest first (the last 500 entries).
  /// It is sorted here (not in Firestore), so entries written by older code
  /// with a different time field are not left out.
  Stream<List<AuditEvent>> watchEvents() async* {
    final people = await _loadPeople();
    yield* _db.collection('audit_log').limit(1000).snapshots().map((snap) {
      final list = [
        for (final d in snap.docs) _toEvent(d.id, d.data(), people),
      ];
      list.sort((a, b) => b.time.compareTo(a.time));
      return list.take(500).toList();
    });
  }

  /// uid -> name and role. If it cannot be read, the email is shown instead.
  Future<Map<String, _Person>> _loadPeople() async {
    try {
      final snap = await _db.collection('users').get();
      return {
        for (final d in snap.docs)
          d.id: _Person(
            ((d.data()['name'] as String?) ?? '').trim(),
            (d.data()['role'] as String?) ?? '',
          ),
      };
    } catch (_) {
      return {};
    }
  }

  // ---------------- Helpers ----------------
  Map<String, dynamic> _map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  int _cents(Object? v) => (v as num?)?.toInt() ?? 0;

  String _cad(int cents) => '${formatCad(cents / 100)} CAD';

  DateTime _timeOf(Map<String, dynamic> m) {
    for (final k in ['at', 'createdAt', 'timestamp']) {
      final v = m[k];
      if (v is Timestamp) return v.toDate();
    }
    return DateTime.now();
  }

  String _roleLabel(String role) {
    if (role.isEmpty) return 'Staff';
    return role[0].toUpperCase() + role.substring(1);
  }

  String _pretty(String type) {
    if (type.isEmpty) return 'Activity';
    final s = type.replaceAll('_', ' ');
    return s[0].toUpperCase() + s.substring(1);
  }

  /// "key: value · key: value" for entries without a special format.
  String? _compact(Map<String, dynamic> d) {
    final parts = <String>[];
    d.forEach((k, v) {
      if (v is Map && v.containsKey('to')) {
        parts.add('$k: ${v['from'] ?? '—'} → ${v['to'] ?? '—'}');
      } else if (v != null && v is! Map && v is! List) {
        parts.add('$k: $v');
      }
    });
    if (parts.isEmpty) return null;
    final s = parts.join(' · ');
    return s.length > 90 ? '${s.substring(0, 90)}…' : s;
  }

  AuditAction _actionFor(String type, Map<String, dynamic> details) {
    if (type == 'stock_adjusted') return AuditAction.stockAdjustment;
       if (type.startsWith('export')) return AuditAction.export;
    if (type == 'order_payment') return AuditAction.payment;
    if (type.startsWith('order')) return AuditAction.order;
    if (type.startsWith('customer')) return AuditAction.customer;
    if (type.startsWith('product')) {
      final priceChanged =
          details.keys.any((k) => k.toLowerCase().contains('price'));
      return priceChanged ? AuditAction.priceChange : AuditAction.product;
    }
    return AuditAction.product;
  }

  _Described _describe(
    String type,
    Map<String, dynamic> m,
    Map<String, dynamic> d,
  ) {
    final orderNo = (m['orderNumber'] as String?) ?? '';
    final customer = (m['customerName'] as String?) ?? '';

    switch (type) {
      case 'order_created':
        return _Described(
          'Created order $orderNo',
          newValue:
              '${_cad(_cents(d['totalCents']))} · paid ${_cad(_cents(d['paidCents']))}',
        );
      case 'order_payment':
        return _Described(
          'Recorded a payment on order $orderNo',
          newValue: '${_cad(_cents(d['amountCents']))} · ${d['method'] ?? ''}',
        );
      case 'order_status':
        final note = d['note'];
        return _Described(
          'Changed the status of order $orderNo',
          oldValue: orderStatusFrom(d['from'] as String?).label,
          newValue: orderStatusFrom(d['to'] as String?).label,
          note: note is String && note.isNotEmpty ? note : null,
        );
      case 'customer_created':
        final phone = d['phone'];
        return _Described(
          'Added customer $customer',
          newValue: phone is String ? formatPhone(phone) : null,
        );
      case 'customer_updated':
        if (d.length == 1) {
          final ch = _map(d.values.first);
          return _Described(
            'Updated ${d.keys.first} of customer $customer',
            oldValue: '${ch['from'] ?? '—'}',
            newValue: '${ch['to'] ?? '—'}',
          );
        }
        return _Described(
          'Updated customer $customer',
          newValue: '${d.length} fields changed',
        );
      case 'customer_note':
        return _Described('Added an after-sales note on $customer');
    }

    // Stock, products and anything else.
    String subject = '';
    for (final k in ['productName', 'productSku', 'sku', 'name']) {
      final v = m[k];
      if (v is String && v.isNotEmpty) {
        subject = v;
        break;
      }
    }
    final reason = d['reason'];
    return _Described(
      subject.isEmpty ? _pretty(type) : '${_pretty(type)}: $subject',
      newValue: _compact(d),
      note: reason is String && reason.isNotEmpty ? reason : null,
    );
  }

  AuditEvent _toEvent(
    String id,
    Map<String, dynamic> m,
    Map<String, _Person> people,
  ) {
    final type = (m['type'] as String?) ?? '';
    final details = _map(m['details']);
    final uid = m['actorUid'] as String?;
    final email = (m['actorEmail'] as String?) ?? '';
    final person = uid == null ? null : people[uid];

    var actor = person?.name ?? '';
    if (actor.isEmpty) {
      actor = email.contains('@') ? email.split('@').first : 'Unknown';
    }
    final role = person?.role ?? '';
    final text = _describe(type, m, details);

    return AuditEvent(
      id: (id.length > 8 ? id.substring(0, 8) : id).toUpperCase(),
      actor: actor,
      actorRole: _roleLabel(role),
      actorInitials: initialsOf(actor),
      isOwner: role == 'owner',
      action: _actionFor(type, details),
      sentence: text.sentence,
      oldValue: text.oldValue,
      newValue: text.newValue,
      note: text.note,
      time: _timeOf(m),
      context: 'Seva POS app',
      terminal: 'Seva POS app',
      device: 'Seva POS app',
      network: '—',
      location: 'Seva POS',
      address: email.isEmpty ? '—' : 'Signed in as $email',
      authorization: email.isEmpty ? 'Signed-in account' : email,
      hash: id,
    );
  }
}