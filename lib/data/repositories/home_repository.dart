import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seva_mattress/modules/orders/order_models.dart'
    show OrderStatus, orderStatusFrom;
import 'package:seva_mattress/modules/sales/sales_models.dart' show PayMethod;

/// One order, reduced to what the Home dashboard needs (amounts in cents).
class HomeOrder {
  const HomeOrder({
    required this.id,
    required this.at,
    required this.status,
    required this.subtotalCents,
    required this.taxCents,
    required this.gstCents,
    required this.pstCents,
    required this.totalCents,
    required this.paidCents,
    required this.units,
    this.discountCents = 0,
    this.refundedCents = 0,
    this.nextPaymentDate,
    this.deliveryDate,
  });

  final String id;
  final DateTime at;
  final OrderStatus status;
  final int subtotalCents;
  final int taxCents;
  final int gstCents;
  final int pstCents;
  final int totalCents;
  final int paidCents;
  final int units;

  /// The discount given on the whole order, and the money already refunded.
  final int discountCents;
  final int refundedCents;
  final DateTime? nextPaymentDate;
  final DateTime? deliveryDate;

  /// Cancelled orders never count in the figures.
  bool get counts => status != OrderStatus.cancelled;

  int get balanceCents => math.max(0, totalCents - paidCents);
}

/// Reads the orders and their payments for the Home dashboard.
class HomeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Live list of the latest 500 orders, newest first.
  Stream<List<HomeOrder>> watchOrders() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) => [for (final d in snap.docs) _fromDoc(d.id, d.data())]);
  }

  HomeOrder _fromDoc(String id, Map<String, dynamic> m) {
    int c(Object? v) => (v as num?)?.toInt() ?? 0;

    final subtotal = c(m['subtotalCents']);
    final tax = c(m['taxCents']);
    final discount = c(m['discountCents']);

    // An order saved before the tax was split has only the total: GST 5%,
    // and the rest is PST.
    int gst;
    int pst;
    if (m['gstCents'] == null) {
      gst = ((subtotal - discount) * 500 + 5000) ~/ 10000;
      pst = math.max(0, tax - gst);
    } else {
      gst = c(m['gstCents']);
      pst = c(m['pstCents']);
    }

    var units = 0;
    for (final l in (m['lines'] as List?) ?? const []) {
      if (l is Map) units += c(l['qty']);
    }

    return HomeOrder(
      id: id,
      at: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: orderStatusFrom(m['status'] as String?),
      subtotalCents: subtotal,
      taxCents: tax,
      gstCents: gst,
      pstCents: pst,
      totalCents: c(m['totalCents']),
      paidCents: c(m['paidCents']),
      units: units,
      discountCents: discount,
      refundedCents: c(m['refundedCents']),
      nextPaymentDate: (m['nextPaymentDate'] as Timestamp?)?.toDate(),
      deliveryDate: (m['deliveryDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Total paid per method, from the payments of the given orders.
  Future<Map<PayMethod, int>> methodTotals(List<String> orderIds) async {
    final out = <PayMethod, int>{for (final m in PayMethod.values) m: 0};
    final snaps = await Future.wait([
      for (final id in orderIds)
        _db.collection('orders').doc(id).collection('payments').get(),
    ]);
    for (final s in snaps) {
      for (final d in s.docs) {
        final m = d.data();
        final cents = (m['amountCents'] as num?)?.toInt() ?? 0;
        final method = switch (m['method']) {
          'Card' => PayMethod.card,
          'Cash' => PayMethod.cash,
          _ => PayMethod.other,
        };
        out[method] = out[method]! + cents;
      }
    }
    return out;
  }
}