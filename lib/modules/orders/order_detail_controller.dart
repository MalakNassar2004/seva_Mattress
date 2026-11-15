import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import 'change_status_sheet.dart';
import 'order_models.dart';
import 'orders_controller.dart';
import 'orders_mock.dart';
import 'record_payment_sheet.dart';

/// Order detail. Opened with the OrderItem as arguments.
/// UI state only. Backend wiring is marked with TODO(backend).
class OrderDetailController extends GetxController {
  /// Stepper labels, in order.
  static const List<String> steps = [
    'Placed',
    'Deposit',
    'In Production',
    'Ready',
    'Out for Delivery',
    'Delivered',
  ];

  // ---------------- Mock data ----------------
  // TODO(backend): load the detail of the order passed in arguments.
  static const OrderDetail detail = OrdersMock.detail;
  final OrderItem? _source =
      Get.arguments is OrderItem ? Get.arguments as OrderItem : null;

  String get number => _source?.number ?? detail.number;
  String get customer => _source?.customer ?? detail.customer;

  // ---------------- State ----------------
  late final status = (_source?.status ?? detail.status).obs;
  final payments = <PaymentRecord>[...detail.payments].obs;
  final timeline = <TimelineEvent>[...detail.timeline].obs;

  double get subtotal =>
      detail.lines.fold(0, (sum, l) => sum + l.price * l.qty);
  double get tax => subtotal * detail.taxRate;
  double get total => subtotal + tax;
  double get paid => payments.fold(0, (sum, p) => sum + p.amount);
  double get balance => (total - paid).clamp(0, double.infinity).toDouble();
  double get paidRatio => total == 0 ? 0 : (paid / total).clamp(0, 1);

  /// Index of the current step in [steps]. All done when Delivered.
  int get currentStep => switch (status.value) {
        OrderStatus.newOrder => paid > 0 ? 2 : 1,
        OrderStatus.inProduction => 2,
        OrderStatus.ready => 3,
        OrderStatus.outForDelivery => 4,
        OrderStatus.delivered => steps.length,
        OrderStatus.cancelled => -1,
      };

  // ---------------- Actions ----------------
  Future<void> onChangeStatusPressed() async {
    final result = await ChangeStatusSheet.open(status.value);
    if (result == null || result.status == status.value) return;
    // TODO(backend): PATCH the order status (and notify the customer if
    // result.notifyCustomer), then reload the timeline.
    status.value = result.status;
    timeline.add(TimelineEvent(
      title: 'Status changed to ${result.status.label}',
      time: 'Just now',
      by: result.note.isEmpty ? 'Owner' : 'Owner · ${result.note}',
    ));
    if (Get.isRegistered<OrdersController>()) {
      Get.find<OrdersController>().updateOrderStatus(number, result.status);
    }
  }

  Future<void> onRecordPaymentPressed() async {
    final record = await RecordPaymentSheet.open(balance: balance);
    if (record == null) return;
    // TODO(backend): POST the payment and use the saved record.
    payments.add(record);
    timeline.add(TimelineEvent(
      title: '${record.kind} received · \$${record.amount.toStringAsFixed(2)}',
      time: 'Just now',
      by: record.method,
    ));
  }

  void onMorePressed() {
    // TODO(design): order actions menu (duplicate, cancel, refund).
  }

  void onBlueprintPressed() {
    // TODO(backend): open the cutting blueprint PDF.
  }

  void onServiceAreaPressed() {
    // TODO(backend): show the delivery zone on a map.
  }

  void onPrintInvoicePressed() {
    // TODO(backend): send the invoice to the showroom printer.
    Get.snackbar('Printing', 'Invoice for $number sent to the printer',
        snackPosition: SnackPosition.BOTTOM, icon: const Icon(Icons.print));
  }

  void onEmailCustomerPressed() {
    // TODO(backend): email the invoice / order summary to the customer.
    Get.snackbar('Email sent', 'Order summary emailed to $customer',
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.mail_outline));
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  /// Delivery team row: opens today's dispatch board.
  void onDeliveriesPressed() => Get.toNamed(AppRoutes.deliveries);
}
