import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/modules/customers/customer_models.dart'
    show formatPhone;
import 'package:seva_mattress/modules/deliveries/delivery_models.dart';
import 'package:seva_mattress/modules/orders/order_models.dart'
    show OrderStatus, fmtOrderDateTime, orderStatusFrom;

/// Turns the orders into the deliveries of the dispatch board. A delivery is
/// an order that has a delivery date, or that is Ready and still waits for
/// one. Cancelled orders never show.
class DeliveriesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get _user => FirebaseAuth.instance.currentUser;

  /// Live deliveries. [firstDay] is the first day of the date strip (local
  /// midnight), [dayCount] its length, [todayIndex] the index of today.
  Stream<List<Delivery>> watchDeliveries({
    required DateTime firstDay,
    required int dayCount,
    required int todayIndex,
  }) {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map((snap) {
      final out = <Delivery>[];
      for (final d in snap.docs) {
        final x = _toDelivery(d.id, d.data(), firstDay, dayCount, todayIndex);
        if (x != null) out.add(x);
      }
      return out;
    });
  }

  /// Days between two dates, safe across daylight saving changes.
  int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  Delivery? _toDelivery(
    String id,
    Map<String, dynamic> m,
    DateTime firstDay,
    int dayCount,
    int todayIndex,
  ) {
    final status = orderStatusFrom(m['status'] as String?);
    if (status == OrderStatus.cancelled) return null;

    final date = (m['deliveryDate'] as Timestamp?)?.toDate();
    final DeliveryStatus ds;
    final int dayIndex;
    if (date != null) {
      dayIndex = _daysBetween(firstDay, date);
      if (dayIndex < 0 || dayIndex >= dayCount) return null;
      ds = status == OrderStatus.delivered
          ? DeliveryStatus.delivered
          : status == OrderStatus.outForDelivery
              ? DeliveryStatus.outForDelivery
              : DeliveryStatus.scheduled;
    } else if (status == OrderStatus.ready) {
      // Ready, but nobody chose a day yet.
      ds = DeliveryStatus.pending;
      dayIndex = todayIndex;
    } else if (status == OrderStatus.outForDelivery) {
      ds = DeliveryStatus.outForDelivery;
      dayIndex = todayIndex;
    } else {
      return null;
    }

    final lines = ((m['lines'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final summary = lines
        .map((l) => '${(l['qty'] as num?)?.toInt() ?? 1}x '
            '${(l['name'] as String?) ?? ''}')
        .join(', ');
    final first = lines.isEmpty
        ? 'Order'
        : ((lines.first['name'] as String?) ?? 'Order');

    final address = ((m['customerAddress'] as String?) ?? '').trim();
    final city = ((m['customerCity'] as String?) ?? '').trim();
    final phone = (m['customerPhone'] as String?) ?? '';
    final total = (m['totalCents'] as num?)?.toInt() ?? 0;
    final paid = (m['paidCents'] as num?)?.toInt() ?? 0;
    final updated = (m['updatedAt'] as Timestamp?)?.toDate();

    return Delivery(
      id: id,
      orderNumber: '#${(m['number'] as String?) ?? ''}',
      customer: (m['customerName'] as String?) ?? '',
      phone: phone.isEmpty ? '' : formatPhone(phone),
      address: address.isNotEmpty
          ? address
          : (city.isNotEmpty ? city : 'No address saved'),
      itemSummary: summary,
      productName: first,
      productTag: 'ORDER',
      amount: total / 100,
      dayIndex: dayIndex,
      window: 'Time not set',
      status: ds,
      timeLabel: ds == DeliveryStatus.delivered && updated != null
          ? fmtOrderDateTime(updated)
          : null,
      paidInFull: total > 0 && paid >= total,
    );
  }

  /// Sets the delivery date of an order. The change goes to the order
  /// timeline. With [backToReady] (a failed attempt) the order also goes back
  /// to Ready, and that is written to the audit log.
  Future<void> reschedule({
    required String orderId,
    required DateTime date,
    required String title,
    String note = '',
    bool backToReady = false,
  }) async {
    final ref = _db.collection('orders').doc(orderId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final o = snap.data();
      if (!snap.exists || o == null) {
        throw StateError('This order no longer exists.');
      }
      final status = (o['status'] as String?) ?? 'new';
      if (status == 'cancelled') {
        throw StateError('This order was cancelled.');
      }
      if (status == 'delivered') {
        throw StateError('This order was already delivered.');
      }

      final now = FieldValue.serverTimestamp();
      final uid = _user?.uid;

      tx.update(ref, {
        'deliveryDate':
            Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        if (backToReady) 'status': 'ready',
        'updatedAt': now,
        'updatedBy': uid,
      });
      tx.set(ref.collection('events').doc(), {
        'title': title.length > 120 ? title.substring(0, 120) : title,
        'by': _user?.email ?? '',
        if (note.isNotEmpty) 'note': note,
        'n': 0,
        'at': now,
        'createdBy': uid,
      });
      if (backToReady && status != 'ready') {
        tx.set(_db.collection('audit_log').doc(), {
          'type': 'order_status',
          'orderId': orderId,
          'orderNumber': (o['number'] as String?) ?? '',
          'details': {
            'from': status,
            'to': 'ready',
            if (note.isNotEmpty) 'note': note,
          },
          'actorUid': uid,
          'actorEmail': _user?.email,
          'at': now,
        });
      }
    });
  }
}