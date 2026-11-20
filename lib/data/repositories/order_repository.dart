import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seva_mattress/app/utils/money.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show PhoneTakenException;
import 'package:seva_mattress/modules/customers/customer_models.dart'
    show formatPhone, customerNumberOf;
import 'package:seva_mattress/modules/orders/order_models.dart';

/// One product line of an order. It is a SNAPSHOT: a later price change does
/// not touch old orders.
class OrderLineInput {
  const OrderLineInput({
    required this.productId,
    required this.sku,
    required this.name,
    required this.details,
    required this.unitCents,
    required this.qty,
    this.trackStock = true,
  });

  final String productId;
  final String sku;
  final String name;
  final String details;
  final int unitCents;
  final int qty;

  /// false for custom-size products: they are made to order, so they are not
  /// taken from the stock.
  final bool trackStock;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'sku': sku,
    'name': name,
    'details': details,
    'unitCents': unitCents,
    'qty': qty,
    'trackStock': trackStock,
  };
}

/// A customer that is saved together with the order.
class NewCustomerInput {
  const NewCustomerInput({
    required this.id,
    required this.name,
    required this.phoneKey,
    required this.city,
  });

  final String id;
  final String name;
  final String phoneKey;
  final String city;
}

/// $120,000.00 (with the thousands separators).
String _money(int cents) => formatCad(cents / 100);

/// A date without a time (local midnight), as it is stored.
DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// All Firestore access for orders. Money is stored in CENTS (whole numbers),
/// so taxes and balances never have rounding surprises.
///
/// Every change is ONE transaction: the order, its payment, the timeline, the
/// customer totals, the stock, the order number and the audit log are saved
/// together or not at all.
class OrderRepository {
  static const int numberBase = 10000;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _customers =>
      _db.collection('customers');
  CollectionReference<Map<String, dynamic>> get _phones =>
      _db.collection('customer_phones');
  CollectionReference<Map<String, dynamic>> get _counters =>
      _db.collection('counters');
  CollectionReference<Map<String, dynamic>> get _audit =>
      _db.collection('audit_log');
  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection('products');

  User? get _user => FirebaseAuth.instance.currentUser;

  /// Ids are created ONCE by the screen, so pressing Save twice (or retrying
  /// on a bad connection) can never create two orders.
  String newOrderId() => _orders.doc().id;
  String newCustomerId() => _customers.doc().id;
  String newPaymentId(String orderId) =>
      _orders.doc(orderId).collection('payments').doc().id;

  // ---------------- Live data ----------------
  Stream<List<OrderItem>> watchOrders() {
    return _orders
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
        final m = d.data();
        final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return orderItemFromMap(d.id, m, at);
      }).toList(),
    );
  }

  Stream<Map<String, dynamic>?> watchOrder(String id) =>
      _orders.doc(id).snapshots().map((s) => s.data());

  Stream<List<PaymentRecord>> watchPayments(String orderId) {
    return _orders
        .doc(orderId)
        .collection('payments')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
        final m = d.data();
        final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return paymentFromMap(d.id, m, at);
      }).toList(),
    );
  }

  Stream<List<TimelineEvent>> watchEvents(String orderId) {
    return _orders
        .doc(orderId)
        .collection('events')
        .orderBy('at')
        .snapshots()
        .map((snap) {
      final rows = snap.docs.map((d) {
        final m = d.data();
        final at = (m['at'] as Timestamp?)?.toDate() ?? DateTime.now();
        final n = (m['n'] as num?)?.toInt() ?? 0;
        final note = (m['note'] as String?) ?? '';
        final by = (m['by'] as String?) ?? '';
        return (
        at,
        n,
        TimelineEvent(
          title: (m['title'] as String?) ?? '',
          time: fmtOrderDateTime(at),
          by: note.isEmpty ? by : '$note · $by',
        ),
        );
      }).toList();
      // Events saved in the same transaction share a timestamp: "n" orders them.
      rows.sort((a, b) {
        final c = a.$1.compareTo(b.$1);
        return c != 0 ? c : a.$2.compareTo(b.$2);
      });
      return [for (final r in rows) r.$3];
    });
  }

  // ---------------- Helpers ----------------
  Map<String, dynamic> _event(String title, {String note = '', int n = 0}) => {
    'title': title,
    'by': _user?.email ?? '',
    if (note.isNotEmpty) 'note': note,
    'n': n,
    'at': FieldValue.serverTimestamp(),
    'createdBy': _user?.uid,
  };

  Map<String, dynamic> _orderAudit(
      String type,
      String orderId,
      String number,
      Map<String, dynamic> details,
      ) =>
      {
        'type': type,
        'orderId': orderId,
        'orderNumber': number,
        'details': details,
        'actorUid': _user?.uid,
        'actorEmail': _user?.email,
        'at': FieldValue.serverTimestamp(),
      };

  Future<PhoneTakenException> _phoneTakenBy(
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

  // ---------------- Create an order ----------------
  /// Creates the order with id [orderId]. The customer is either an existing
  /// one ([customerId]), a new one saved together with the order
  /// ([newCustomer]), or neither (a walk-in sale).
  ///
  /// The discount ([discountCents], only the owner can give one) comes off
  /// the items BEFORE the tax. GST ([gstBp]) and PST ([pstBp]) are worked out
  /// on what is left, in basis points (500 = 5%), each one rounded to the
  /// nearest cent on its own, and both are saved on the order.
  ///
  /// The stock of every tracked product goes down in the same transaction
  /// (showroom first, then warehouse). If there is not enough stock, nothing
  /// is saved.
  ///
  /// [nextPaymentDate]: when the next payment is due (only kept while there
  /// is a balance). [deliveryDate]: when the order should be delivered.
  Future<OrderItem> createOrder({
    required String orderId,
    required List<OrderLineInput> lines,
    String? customerId,
    NewCustomerInput? newCustomer,
    int gstBp = 500,
    int pstBp = 700,
    bool isCustom = false,
    Map<String, dynamic>? spec,
    int depositCents = 0,
    String depositMethod = 'Cash',
    DateTime? nextPaymentDate,
    DateTime? deliveryDate,
    int discountCents = 0,
    String discountKind = '',
    int discountValue = 0,
    String discountReason = '',
  }) async {
    if (lines.isEmpty) throw StateError('Add at least one item.');
    final orderRef = _orders.doc(orderId);
    Map<String, dynamic>? saved;

    await _db.runTransaction((tx) async {
      // ---------- reads ----------
      final existing = await tx.get(orderRef);
      if (existing.exists) {
        // A retry of a save that already went through (slow connection).
        saved = existing.data();
        return;
      }

      final counterRef = _counters.doc('orders');
      final counter = await tx.get(counterRef);
      final seq = ((counter.data()?['last'] as num?)?.toInt() ?? 0) + 1;

      String? customerRefId;
      var customerName = 'Walk-in customer';
      var customerPhone = '';
      var customerCity = '';
      var customerAddress = '';
      DocumentReference<Map<String, dynamic>>? newCustomerRef;
      DocumentReference<Map<String, dynamic>>? claimRef;
      DocumentReference<Map<String, dynamic>>? customerCounterRef;
      DocumentSnapshot<Map<String, dynamic>>? customerCounter;
      var customerSeq = 0;

      if (newCustomer != null) {
        claimRef = _phones.doc(newCustomer.phoneKey);
        final claim = await tx.get(claimRef);
        if (claim.exists) {
          throw await _phoneTakenBy(tx, newCustomer.phoneKey, claim.data());
        }
        // The new customer also gets the next number (CUST-0001...).
        customerCounterRef = _counters.doc('customers');
        customerCounter = await tx.get(customerCounterRef);
        customerSeq =
            ((customerCounter.data()?['last'] as num?)?.toInt() ?? 0) + 1;

        newCustomerRef = _customers.doc(newCustomer.id);
        customerRefId = newCustomer.id;
        customerName = newCustomer.name;
        customerPhone = newCustomer.phoneKey;
        customerCity = newCustomer.city;
      } else if (customerId != null) {
        final snap = await tx.get(_customers.doc(customerId));
        final m = snap.data();
        if (!snap.exists || m == null || m['deleted'] == true) {
          throw StateError('This customer no longer exists.');
        }
        customerRefId = customerId;
        customerName = (m['name'] as String?) ?? '';
        customerPhone = (m['phone'] as String?) ?? '';
        customerCity = (m['city'] as String?) ?? '';
        customerAddress = (m['address'] as String?) ?? '';
      }

      // ---------- stock (still reads: nothing is written yet) ----------
      // Tracked products come out of the showroom first, then the warehouse.
      final need = <String, int>{};
      final names = <String, String>{};
      for (final l in lines) {
        if (!l.trackStock) continue;
        need[l.productId] = (need[l.productId] ?? 0) + l.qty;
        names[l.productId] = l.name;
      }
      final stockUpdates =
      <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};
      final stockLog = <Map<String, dynamic>>[];
      for (final e in need.entries) {
        final ref = _products.doc(e.key);
        final snap = await tx.get(ref);
        final p = snap.data();
        if (!snap.exists || p == null || p['deleted'] == true) {
          throw StateError('${names[e.key]} is no longer in the product list.');
        }
        final warehouse = (p['units'] as num?)?.toInt() ?? 0;
        final showroom = (p['showroomUnits'] as num?)?.toInt() ?? 0;
        if (e.value > warehouse + showroom) {
          throw StateError(
            'Not enough stock for ${names[e.key]}: '
                '${warehouse + showroom} available.',
          );
        }
        final fromShowroom = e.value < showroom ? e.value : showroom;
        final fromWarehouse = e.value - fromShowroom;
        stockUpdates[ref] = {
          if (fromWarehouse > 0) 'units': warehouse - fromWarehouse,
          if (fromShowroom > 0) 'showroomUnits': showroom - fromShowroom,
        };
        stockLog.add({
          'productId': e.key,
          'name': names[e.key],
          'qty': e.value,
        });
      }

      // ---------- amounts (cents) ----------
      var subtotal = 0;
      for (final l in lines) {
        subtotal += l.unitCents * l.qty;
      }
      if (discountCents < 0 || discountCents >= subtotal) {
        throw StateError('The discount cannot be the whole order.');
      }
      // The discount comes off BEFORE the tax. GST and PST are worked out on
      // what is left, each rounded to the nearest cent on its own.
      final taxable = subtotal - discountCents;
      final gst = (taxable * gstBp + 5000) ~/ 10000;
      final pst = (taxable * pstBp + 5000) ~/ 10000;
      final tax = gst + pst;
      final total = taxable + tax;
      if (depositCents < 0 || depositCents > total) {
        throw StateError('The payment is more than the order total.');
      }
      final balance = total - depositCents;

      // ---------- writes ----------
      final now = FieldValue.serverTimestamp();
      final uid = _user?.uid;
      final email = _user?.email ?? '';
      final number = 'ORD-${numberBase + seq}';

      if (counter.exists) {
        tx.update(counterRef, {'last': seq});
      } else {
        tx.set(counterRef, {'last': seq});
      }

      stockUpdates.forEach((ref, data) {
        if (data.isNotEmpty) tx.update(ref, data);
      });

      if (newCustomerRef != null &&
          claimRef != null &&
          customerCounterRef != null &&
          customerCounter != null) {
        final customerNumber = customerNumberOf(customerSeq);

        if (customerCounter.exists) {
          tx.update(customerCounterRef, {'last': customerSeq});
        } else {
          tx.set(customerCounterRef, {'last': customerSeq});
        }
        tx.set(newCustomerRef, {
          'name': customerName,
          'nameLower': customerName.toLowerCase(),
          'phone': customerPhone,
          'email': '',
          'city': customerCity,
          'address': '',
          'notes': '',
          'number': customerNumber,
          'seq': customerSeq,
          'orderCount': 1,
          'balanceCents': balance,
          'totalCents': total,
          'deleted': false,
          'createdAt': now,
          'createdBy': uid,
          'updatedAt': now,
          'updatedBy': uid,
        });
        tx.set(claimRef, {
          'phone': customerPhone,
          'customerId': customerRefId,
          'createdAt': now,
          'createdBy': uid,
        });
        tx.set(_audit.doc(), {
          'type': 'customer_created',
          'customerId': customerRefId,
          'customerName': customerName,
          'details': {
            'phone': customerPhone,
            'number': customerNumber,
            'with': number,
          },
          'actorUid': uid,
          'actorEmail': email,
          'at': now,
        });
      } else if (customerRefId != null) {
        tx.update(_customers.doc(customerRefId), {
          'orderCount': FieldValue.increment(1),
          'balanceCents': FieldValue.increment(balance),
          'totalCents': FieldValue.increment(total),
          'updatedAt': now,
          'updatedBy': uid,
        });
      }

      final data = <String, dynamic>{
        'number': number,
        'seq': seq,
        'status': 'new',
        'customerId': customerRefId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerCity': customerCity,
        'customerAddress': customerAddress,
        'lines': [for (final l in lines) l.toMap()],
        'subtotalCents': subtotal,
        // The discount on the whole order (only when there is one).
        if (discountCents > 0) ...{
          'discountCents': discountCents,
          'discountKind': discountKind,
          'discountValue': discountValue,
          'discountReason': discountReason,
        },
        // Taxes: the total, and the two parts (GST + PST).
        'taxBp': gstBp + pstBp,
        'taxCents': tax,
        'gstBp': gstBp,
        'gstCents': gst,
        'pstBp': pstBp,
        'pstCents': pst,
        'totalCents': total,
        'paidCents': depositCents,
        'isCustom': isCustom,
        'spec': isCustom ? spec : null,
        // true: the stock of the tracked lines was taken at the sale, so a
        // cancel or a refund can put it back. Older orders do not have it.
        'stockTracked': true,
        // The next payment only makes sense while there is a balance.
        if (nextPaymentDate != null && balance > 0)
          'nextPaymentDate': Timestamp.fromDate(_day(nextPaymentDate)),
        if (deliveryDate != null)
          'deliveryDate': Timestamp.fromDate(_day(deliveryDate)),
        'createdAt': now,
        'createdBy': uid,
        'createdByEmail': email,
        'updatedAt': now,
        'updatedBy': uid,
      };
      tx.set(orderRef, data);

      tx.set(orderRef.collection('events').doc(), _event('Order placed'));

      if (discountCents > 0) {
        tx.set(
          orderRef.collection('events').doc(),
          _event(
            'Discount given · ${_money(discountCents)}',
            note: discountReason,
            n: 1,
          ),
        );
      }

      if (depositCents > 0) {
        final kind = depositCents >= total ? 'Payment in full' : 'Deposit';
        tx.set(orderRef.collection('payments').doc(), {
          'method': depositMethod,
          'kind': kind,
          'amountCents': depositCents,
          'reference': '',
          'createdAt': now,
          'createdBy': uid,
          'createdByEmail': email,
        });
        tx.set(
          orderRef.collection('events').doc(),
          _event(
            '$kind received · ${_money(depositCents)}',
            note: depositMethod,
            n: 2,
          ),
        );
      }

      tx.set(
        _audit.doc(),
        _orderAudit('order_created', orderId, number, {
          'totalCents': total,
          if (discountCents > 0) 'discountCents': discountCents,
          'gstCents': gst,
          'pstCents': pst,
          'paidCents': depositCents,
          'customerId': customerRefId,
          'stock': stockLog,
        }),
      );

      saved = data;
    });

    return orderItemFromMap(orderId, saved!, DateTime.now());
  }

  // ---------------- Record a payment ----------------
  /// Adds a payment. [paymentId] is created once per payment screen, so a
  /// retry can never record the same payment twice.
  ///
  /// [nextPaymentDate]: when the next payment is due. When this payment
  /// settles the order, the date is removed.
  Future<void> recordPayment({
    required String orderId,
    required String paymentId,
    required int amountCents,
    required String method,
    String reference = '',
    DateTime? nextPaymentDate,
  }) async {
    final orderRef = _orders.doc(orderId);
    final payRef = orderRef.collection('payments').doc(paymentId);

    await _db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      final o = order.data();
      if (!order.exists || o == null) {
        throw StateError('This order no longer exists.');
      }
      final already = await tx.get(payRef);
      if (already.exists) return; // a retry that already went through

      if (o['status'] == 'cancelled') {
        throw StateError('This order was cancelled.');
      }
      if (amountCents <= 0) throw StateError('Enter an amount above \$0.00.');

      final total = (o['totalCents'] as num?)?.toInt() ?? 0;
      final paid = (o['paidCents'] as num?)?.toInt() ?? 0;
      final balance = total - paid;
      if (amountCents > balance) {
        throw StateError(
          'The amount is more than the balance owing (${_money(balance)}).',
        );
      }

      final settled = amountCents == balance;
      final kind = settled ? 'Final balance' : 'Partial payment';
      final now = FieldValue.serverTimestamp();
      final uid = _user?.uid;
      final email = _user?.email ?? '';

      tx.set(payRef, {
        'method': method,
        'kind': kind,
        'amountCents': amountCents,
        'reference': reference,
        'createdAt': now,
        'createdBy': uid,
        'createdByEmail': email,
      });
      tx.update(orderRef, {
        'paidCents': paid + amountCents,
        if (settled)
          'nextPaymentDate': FieldValue.delete()
        else if (nextPaymentDate != null)
          'nextPaymentDate': Timestamp.fromDate(_day(nextPaymentDate)),
        'updatedAt': now,
        'updatedBy': uid,
      });

      final customerId = o['customerId'] as String?;
      if (customerId != null) {
        tx.update(_customers.doc(customerId), {
          'balanceCents': FieldValue.increment(-amountCents),
          'updatedAt': now,
          'updatedBy': uid,
        });
      }

      tx.set(
        orderRef.collection('events').doc(),
        _event(
          '$kind received · ${_money(amountCents)}',
          note: reference.isEmpty ? method : '$method · $reference',
        ),
      );
      tx.set(
        _audit.doc(),
        _orderAudit('order_payment', orderId, (o['number'] as String?) ?? '', {
          'amountCents': amountCents,
          'method': method,
          'kind': kind,
        }),
      );
    });
  }

  // ---------------- Change the status ----------------
  /// Changes the status. Cancelling an order also puts its stock back (the
  /// items that a refund did not already return), in the same transaction.
  Future<void> changeStatus({
    required String orderId,
    required String newStatus,
    String note = '',
  }) async {
    final orderRef = _orders.doc(orderId);

    await _db.runTransaction((tx) async {
      final order = await tx.get(orderRef);
      final o = order.data();
      if (!order.exists || o == null) {
        throw StateError('This order no longer exists.');
      }
      final old = (o['status'] as String?) ?? 'new';
      if (old == 'cancelled') {
        throw StateError('This order was cancelled and cannot change.');
      }
      if (old == newStatus) return;

      // ---------- stock to put back (reads, before any write) ----------
      final restock = <DocumentReference<Map<String, dynamic>>, int>{};
      final restockLog = <Map<String, dynamic>>[];
      if (newStatus == 'cancelled' && o['stockTracked'] == true) {
        final returned = o['returnedUnits'] is Map
            ? Map<String, dynamic>.from(o['returnedUnits'] as Map)
            : <String, dynamic>{};
        final qtyBy = <String, int>{};
        for (final l in (o['lines'] as List?) ?? const []) {
          if (l is Map && l['trackStock'] == true) {
            final id = (l['productId'] as String?) ?? '';
            if (id.isEmpty) continue;
            qtyBy[id] = (qtyBy[id] ?? 0) + ((l['qty'] as num?)?.toInt() ?? 0);
          }
        }
        for (final e in qtyBy.entries) {
          final back = e.value - ((returned[e.key] as num?)?.toInt() ?? 0);
          if (back <= 0) continue;
          final ref = _products.doc(e.key);
          final snap = await tx.get(ref);
          final p = snap.data();
          if (!snap.exists || p == null) continue; // the product was removed
          final warehouse = (p['units'] as num?)?.toInt() ?? 0;
          restock[ref] = warehouse + back;
          restockLog.add({'productId': e.key, 'qty': back});
        }
      }

      final now = FieldValue.serverTimestamp();
      final uid = _user?.uid;

      tx.update(orderRef, {
        'status': newStatus,
        // A cancelled order has no next payment.
        if (newStatus == 'cancelled') 'nextPaymentDate': FieldValue.delete(),
        'updatedAt': now,
        'updatedBy': uid,
      });

      restock.forEach((ref, units) => tx.update(ref, {'units': units}));

      // A cancelled order is no longer owed by the customer, and it no longer
      // counts in his total (VIP).
      final customerId = o['customerId'] as String?;
      if (newStatus == 'cancelled' && customerId != null) {
        final total = (o['totalCents'] as num?)?.toInt() ?? 0;
        final paid = (o['paidCents'] as num?)?.toInt() ?? 0;
        tx.update(_customers.doc(customerId), {
          'balanceCents': FieldValue.increment(-(total - paid)),
          'totalCents': FieldValue.increment(-total),
          'orderCount': FieldValue.increment(-1),
          'updatedAt': now,
          'updatedBy': uid,
        });
      }

      final label = orderStatusFrom(newStatus).label;
      tx.set(
        orderRef.collection('events').doc(),
        _event('Status changed to $label', note: note),
      );
      tx.set(
        _audit.doc(),
        _orderAudit('order_status', orderId, (o['number'] as String?) ?? '', {
          'from': old,
          'to': newStatus,
          if (note.isNotEmpty) 'note': note,
          if (restockLog.isNotEmpty) 'stockReturned': restockLog,
        }),
      );
    });
  }
}