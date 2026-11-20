import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/app/utils/money.dart';

/// Refunds of an order. A refund is money given back to the customer. It never
/// changes the items, the total or the balance owing of the order.
///
/// Everything is ONE transaction: the refund, the refunded total of the order,
/// the units that came back, the stock, the customer total, the timeline and
/// the audit log.
///
/// Each returned item says if it is [damaged]. A sellable unit goes back to
/// the warehouse stock, a damaged one to the damaged stock. Custom products
/// and orders made before the stock was tracked are not put back.
class RefundRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get _user => FirebaseAuth.instance.currentUser;

  /// Created ONCE per refund, so a retry can never refund twice.
  String newRefundId(String orderId) =>
      _db.collection('orders').doc(orderId).collection('refunds').doc().id;

  /// [items]: {productId, name, qty, unitCents, damaged, trackStock}.
  Future<void> refund({
    required String orderId,
    required String refundId,
    required int amountCents,
    required String method,
    required String reason,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final orderRef = _db.collection('orders').doc(orderId);
    final refundRef = orderRef.collection('refunds').doc(refundId);

    await _db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      final o = order.data();
      if (!order.exists || o == null) {
        throw StateError('This order no longer exists.');
      }
      final already = await tx.get(refundRef);
      if (already.exists) return; // a retry that already went through

      final paid = (o['paidCents'] as num?)?.toInt() ?? 0;
      final refunded = (o['refundedCents'] as num?)?.toInt() ?? 0;
      final max = paid - refunded;
      if (amountCents <= 0) throw StateError('Enter an amount above \$0.00.');
      if (amountCents > max) {
        throw StateError(
          'The most that can be refunded is ${formatCad(max / 100)}.',
        );
      }

      final status = (o['status'] as String?) ?? 'new';

      // ---------- units that come back (reads before any write) ----------
      final sellableBy = <String, int>{};
      final damagedBy = <String, int>{};
      final returned = o['returnedUnits'] is Map
          ? Map<String, dynamic>.from(o['returnedUnits'] as Map)
          : <String, dynamic>{};
      final newReturned = Map<String, dynamic>.from(returned);

      if (o['stockTracked'] == true && status != 'cancelled') {
        final bought = <String, int>{};
        for (final l in (o['lines'] as List?) ?? const []) {
          if (l is Map && l['trackStock'] == true) {
            final id = (l['productId'] as String?) ?? '';
            if (id.isEmpty) continue;
            bought[id] = (bought[id] ?? 0) + ((l['qty'] as num?)?.toInt() ?? 0);
          }
        }

        for (final it in items) {
          if (it['trackStock'] != true) continue;
          final id = (it['productId'] as String?) ?? '';
          final qty = (it['qty'] as num?)?.toInt() ?? 0;
          if (id.isEmpty || qty <= 0) continue;
          if (!bought.containsKey(id)) {
            throw StateError('An item of this refund is not in the order.');
          }
          if (it['damaged'] == true) {
            damagedBy[id] = (damagedBy[id] ?? 0) + qty;
          } else {
            sellableBy[id] = (sellableBy[id] ?? 0) + qty;
          }
        }

        final ids = {...sellableBy.keys, ...damagedBy.keys};
        for (final id in ids) {
          final now = (sellableBy[id] ?? 0) + (damagedBy[id] ?? 0);
          final before = (returned[id] as num?)?.toInt() ?? 0;
          if (before + now > (bought[id] ?? 0)) {
            throw StateError(
              'You cannot return more units than were bought.',
            );
          }
          newReturned[id] = before + now;
        }
      }

      final productUpdates =
          <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};
      final restockLog = <Map<String, dynamic>>[];
      for (final id in {...sellableBy.keys, ...damagedBy.keys}) {
        final ref = _db.collection('products').doc(id);
        final snap = await tx.get(ref);
        final p = snap.data();
        if (!snap.exists || p == null) continue; // the product was removed
        final s = sellableBy[id] ?? 0;
        final d = damagedBy[id] ?? 0;
        productUpdates[ref] = {
          if (s > 0) 'units': ((p['units'] as num?)?.toInt() ?? 0) + s,
          if (d > 0)
            'damagedUnits': ((p['damagedUnits'] as num?)?.toInt() ?? 0) + d,
        };
        restockLog.add({'productId': id, 'sellable': s, 'damaged': d});
      }

      // ---------- writes ----------
      final now = FieldValue.serverTimestamp();
      final uid = _user?.uid;
      final email = _user?.email ?? '';
      final number = (o['number'] as String?) ?? '';

      tx.set(refundRef, {
        'amountCents': amountCents,
        'method': method,
        'reason': reason,
        'items': items,
        'createdAt': now,
        'createdBy': uid,
        'createdByEmail': email,
      });

      tx.update(orderRef, {
        'refundedCents': refunded + amountCents,
        if (newReturned.isNotEmpty) 'returnedUnits': newReturned,
        'updatedAt': now,
        'updatedBy': uid,
      });

      productUpdates.forEach((ref, data) {
        if (data.isNotEmpty) tx.update(ref, data);
      });

      // A cancelled order was already taken out of the customer total.
      final customerId = o['customerId'] as String?;
      if (customerId != null && status != 'cancelled') {
        tx.update(_db.collection('customers').doc(customerId), {
          'totalCents': FieldValue.increment(-amountCents),
          'updatedAt': now,
          'updatedBy': uid,
        });
      }

      final title = 'Refund issued · ${formatCad(amountCents / 100)}';
      tx.set(orderRef.collection('events').doc(), {
        'title': title.length > 120 ? title.substring(0, 120) : title,
        'by': email,
        'note': '$method · $reason',
        'n': 0,
        'at': now,
        'createdBy': uid,
      });

      tx.set(_db.collection('audit_log').doc(), {
        'type': 'order_refund',
        'orderId': orderId,
        'orderNumber': number,
        'details': {
          'amountCents': amountCents,
          'method': method,
          'reason': reason,
          if (restockLog.isNotEmpty) 'stockReturned': restockLog,
        },
        'actorUid': uid,
        'actorEmail': email,
        'at': now,
      });
    });
  }
}