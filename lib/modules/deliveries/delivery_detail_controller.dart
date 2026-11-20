import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/modules/orders/order_models.dart'
    show orderItemFromMap;
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes/app_routes.dart';
import 'deliveries_controller.dart';
import 'deliveries_mock.dart';
import 'delivery_models.dart';

/// Delivery detail. Opened with the order id as arguments.
/// Reads and writes through DeliveriesController so the board stays in sync.
class DeliveryDetailController extends GetxController {
  final String id = Get.arguments is String ? Get.arguments as String : '';

  DeliveriesController get _board => Get.find<DeliveriesController>();

  /// Shown only for a moment, or when the order left the board (cancelled,
  /// or its date is outside the strip).
  Delivery get _empty => Delivery(
        id: id,
        orderNumber: '',
        customer: '',
        phone: '',
        address: '',
        itemSummary: '',
        productName: '',
        productTag: 'ORDER',
        amount: 0,
        dayIndex: DeliveriesMock.todayIndex,
        window: '',
        status: DeliveryStatus.pending,
      );

  Delivery get delivery => _board.byId(id) ?? _empty;

  DispatchDay get day => DeliveriesMock.days[delivery.dayIndex];

  // ---------------- Actions ----------------
  Future<void> onAssignPressed() => _board.onAssignDriver(delivery);

  Future<void> onReschedulePressed() => _board.onReschedule(delivery);

  void onCallDriverPressed() {
    final d = delivery.driver;
    if (d != null) _board.onCallDriver(d);
  }

  Future<void> onCallCustomerPressed() async {
    final digits = delivery.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      Get.snackbar('No phone', 'This customer has no phone number.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      final ok = await launchUrl(Uri(scheme: 'tel', path: digits));
      if (!ok) throw StateError('Cannot open the dialer');
    } catch (_) {
      Get.snackbar('Could not call', delivery.phone,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> onMarkOutPressed() =>
      _board.setOrderStatus(delivery, 'outForDelivery');

  Future<void> onMarkDeliveredPressed() =>
      _board.setOrderStatus(delivery, 'delivered');

  Future<void> onMarkFailedPressed() => _board.onReportFailed(delivery);

  void onProofTap(int index) {
    // Proof photos need cloud storage: not built yet.
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  /// Opens the order of this delivery.
  Future<void> onOpenOrderPressed() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('orders').doc(id).get();
      final m = snap.data();
      if (m == null) return;
      final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      Get.toNamed(AppRoutes.orderDetail, arguments: orderItemFromMap(id, m, at));
    } catch (_) {
      Get.snackbar('Could not open the order', 'Check the connection.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}