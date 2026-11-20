import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:seva_mattress/modules/sales/sales_models.dart';

/// Reads the orders and turns them into the "sales" of Reports and
/// Transactions. The orders are the only source of the figures.
class SalesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOrders() => _db
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .limit(500)
      .snapshots();

  /// The payments and the timeline of every order (collection group).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPayments() =>
      _db.collectionGroup('payments').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEvents() =>
      _db.collectionGroup('events').snapshots();

  /// Cost price per product id. Only the owner can read them: null when they
  /// cannot be read.
  Future<Map<String, double>?> loadCosts() async {
    try {
      final snap = await _db.collection('product_costs').get();
      return {
        for (final d in snap.docs)
          ((d.data()['productId'] as String?) ?? d.id):
              (d.data()['costPrice'] as num?)?.toDouble() ?? 0,
      };
    } catch (_) {
      return null;
    }
  }

  // ---------------- Grouping ----------------
  static Map<String, List<SalePayment>> groupPayments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final rows = <String, List<(DateTime, SalePayment)>>{};
    for (final d in docs) {
      final id = d.reference.parent.parent?.id;
      if (id == null) continue;
      final m = d.data();
      final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final method = (m['method'] as String?) ?? 'Cash';
      final ref = (m['reference'] as String?) ?? '';
      (rows[id] ??= []).add((
        at,
        SalePayment(
          method: method == 'Card'
              ? PayMethod.card
              : method == 'Cash'
              ? PayMethod.cash
              : PayMethod.other,
          label: method,
          reference: ref.isEmpty ? ((m['kind'] as String?) ?? '') : ref,
          amount: ((m['amountCents'] as num?)?.toInt() ?? 0) / 100,
        ),
      ));
    }
    return {
      for (final e in rows.entries)
        e.key: (e.value..sort((a, b) => a.$1.compareTo(b.$1)))
            .map((r) => r.$2)
            .toList(),
    };
  }

  static IconData _eventIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('refund')) return Icons.undo;
    if (t.contains('discount')) return Icons.local_offer_outlined;
    if (t.contains('received') || t.contains('deposit')) {
      return Icons.payments_outlined;
    }
    if (t.contains('status')) return Icons.sync;
    return Icons.receipt_long_outlined;
  }

  static Map<String, List<SaleEvent>> groupEvents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final rows = <String, List<(DateTime, int, SaleEvent)>>{};
    for (final d in docs) {
      final id = d.reference.parent.parent?.id;
      if (id == null) continue;
      final m = d.data();
      final at = (m['at'] as Timestamp?)?.toDate() ?? DateTime.now();
      final n = (m['n'] as num?)?.toInt() ?? 0;
      final title = (m['title'] as String?) ?? '';
      final note = (m['note'] as String?) ?? '';
      final by = (m['by'] as String?) ?? '';
      (rows[id] ??= []).add((
        at,
        n,
        SaleEvent(
          title,
          note.isEmpty ? by : '$note · $by',
          at,
          icon: _eventIcon(title),
        ),
      ));
    }
    return {
      for (final e in rows.entries)
        e.key: (e.value
              ..sort((a, b) {
                final c = a.$1.compareTo(b.$1);
                return c != 0 ? c : a.$2.compareTo(b.$2);
              }))
            .map((r) => r.$3)
            .toList(),
    };
  }

  static ProductType _typeOf(Map<String, dynamic> line) {
    final d = ((line['details'] as String?) ?? '').toLowerCase();
    if (d.startsWith('pillows')) return ProductType.pillow;
    if (d.startsWith('protectors')) return ProductType.protector;
    if (d.startsWith('accessories')) return ProductType.accessory;
    if (line['trackStock'] == false) return ProductType.customSize;
    return ProductType.mattress;
  }

  /// Turns one order into a [Sale].
  static Sale toSale(
    String id,
    Map<String, dynamic> m, {
    required List<SalePayment> payments,
    required List<SaleEvent> events,
    Map<String, double>? costs,
  }) {
    int c(Object? v) => (v as num?)?.toInt() ?? 0;

    final lines = <SaleLine>[
      for (final l in ((m['lines'] as List?) ?? const []))
        if (l is Map)
          () {
            final map = Map<String, dynamic>.from(l);
            final details = (map['details'] as String?) ?? '';
            final parts = details.split(' · ');
            return SaleLine(
              name: (map['name'] as String?) ?? '',
              size: parts.length > 1 ? parts[1] : (map['sku'] as String?) ?? '',
              qty: c(map['qty']),
              price: c(map['unitCents']) / 100,
              cost: costs?[(map['productId'] as String?) ?? ''] ?? 0,
              type: _typeOf(map),
            );
          }(),
    ];

    final subtotal = c(m['subtotalCents']);
    final tax = c(m['taxCents']);
    final total = c(m['totalCents']);
    final paid = c(m['paidCents']);
    final refunded = c(m['refundedCents']);
    final discount = c(m['discountCents']);

    // An order saved before the tax was split has only the total: GST 5%,
    // and the rest is PST.
    int gst;
    int pst;
    if (m['gstCents'] == null) {
      gst = ((subtotal - discount) * 500 + 5000) ~/ 10000;
      pst = tax - gst;
    } else {
      gst = c(m['gstCents']);
      pst = c(m['pstCents']);
    }

    final status = (m['status'] as String?) ?? 'new';
    final SaleStatus saleStatus;
    if (status == 'cancelled') {
      saleStatus = SaleStatus.voided;
    } else if (refunded > 0 && refunded >= paid && paid > 0) {
      saleStatus = SaleStatus.refunded;
    } else if (paid >= total && total > 0) {
      saleStatus = SaleStatus.paid;
    } else if (paid > 0) {
      saleStatus = SaleStatus.deposit;
    } else {
      saleStatus = SaleStatus.unpaid;
    }

    final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final by = (m['createdByEmail'] as String?) ?? '';

    return Sale(
      invoice: (m['number'] as String?) ?? id,
      customer: (m['customerName'] as String?) ?? '',
      cashier: by.contains('@') ? by.split('@').first : by,
      time: at,
      lines: lines,
      payments: payments,
      status: saleStatus,
      timeline: events,
      discount: discount / 100,
      note: m['isCustom'] == true ? 'Custom build' : null,
      refunded: refunded / 100,
      refundState:
          refunded > 0 ? RefundState.completed : RefundState.none,
      orderId: id,
      gstAmount: gst / 100,
      pstAmount: pst / 100,
    );
  }
}