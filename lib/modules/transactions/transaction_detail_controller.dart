import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/repositories/order_repository.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../orders/order_models.dart';
import '../orders/refund_sheet.dart';
import '../sales/sales_models.dart';
import '../sales/sales_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction detail. Arguments: invoice number (String). The sale is a
/// real order; Refund and Void act on that order.
class TransactionDetailController extends GetxController {
  final store = SalesStore.to;
  late final String invoice = Get.arguments as String;

  /// Owner-only cost & margin, hidden until the eye is tapped.
  final costVisible = false.obs;

  Sale get sale => store.byInvoice(invoice) ?? _empty;

  static final Sale _empty = Sale(
    invoice: '',
    customer: '',
    cashier: '',
    time: DateTime.now(),
    lines: const [],
    payments: const [],
    status: SaleStatus.voided,
    timeline: const [],
  );

  double get refundable => (sale.paid - sale.refunded).clamp(0, sale.paid);

  bool get canRefund =>
      sale.orderId.isNotEmpty &&
      sale.status != SaleStatus.voided &&
      refundable > 0.01;

  bool get canVoid =>
      sale.orderId.isNotEmpty &&
      sale.status != SaleStatus.voided &&
      sale.refunded == 0;

  // ---------------- Actions ----------------
  void toggleCost() => costVisible.toggle();

  Future<void> _openOrder() async {
    final s = sale;
    if (s.orderId.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .doc(s.orderId)
        .get();
    final m = snap.data();
    if (m == null) return;
    final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    Get.toNamed(
      AppRoutes.orderDetail,
      arguments: orderItemFromMap(s.orderId, m, at),
    );
  }

  /// Print and email are done from the order page (real invoice PDF).
  void onPrint() => _openOrder();
  void onEmail() => _openOrder();

  Future<void> onRefund() async {
    final s = sale;
    if (!canRefund) return;
    final snap = await FirebaseFirestore.instance
        .collection('orders')
        .doc(s.orderId)
        .get();
    final m = snap.data();
    if (m == null) return;
    await RefundFlow.start(orderId: s.orderId, order: m);
  }

  Future<void> onVoid() async {
    final s = sale;
    if (!canVoid) return;

    var allowed = false;
    try {
      final u = await SessionService().loadCurrentUser();
      allowed = (u?.isOwner ?? false) || (u?.isManager ?? false);
    } catch (_) {}
    if (!allowed) {
      showDarkToast('Only the owner or a manager can void',
          trailing: '', info: true);
      return;
    }

    final ok = await showConfirmSheet(
      title: 'Void invoice #${s.invoice}?',
      message:
          'The order is cancelled, its stock goes back, and it no longer '
          'counts in the sales. Payments already taken must be refunded '
          'separately.',
      confirmLabel: 'Void invoice',
      icon: Icons.block,
      danger: true,
    );
    if (!ok) return;

    try {
      await OrderRepository().changeStatus(
        orderId: s.orderId,
        newStatus: 'cancelled',
        note: 'Voided from Transactions',
      );
      showDarkToast('Invoice #${s.invoice} voided');
    } catch (e) {
      showDarkToast(describeCustomerError(e), trailing: '', info: true);
    }
  }

  void onBackPressed() => Get.back();
}