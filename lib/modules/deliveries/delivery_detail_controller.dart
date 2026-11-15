import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import 'deliveries_controller.dart';
import 'deliveries_mock.dart';
import 'delivery_models.dart';

/// Delivery detail. Opened with the delivery id as arguments.
/// Reads and writes through DeliveriesController so the board stays in sync.
/// UI state only. Backend wiring is marked with TODO(backend).
class DeliveryDetailController extends GetxController {
  final String id = Get.arguments is String
      ? Get.arguments as String
      : DeliveriesMock.deliveries.first.id;

  DeliveriesController get _board => Get.find<DeliveriesController>();

  // TODO(backend): load the delivery by id.
  Delivery get delivery =>
      _board.byId(id) ?? DeliveriesMock.deliveries.first;

  DispatchDay get day => DeliveriesMock.days[delivery.dayIndex];

  // ---------------- Actions ----------------
  Future<void> onAssignPressed() => _board.onAssignDriver(delivery);

  Future<void> onReschedulePressed() => _board.onReschedule(delivery);

  void onCallDriverPressed() {
    final d = delivery.driver;
    if (d != null) _board.onCallDriver(d);
  }

  void onCallCustomerPressed() {
    // TODO(backend): launch the dialer with delivery.phone.
    Get.snackbar('Calling ${delivery.customer}', delivery.phone,
        snackPosition: SnackPosition.BOTTOM, icon: const Icon(Icons.call));
  }

  void onMarkOutPressed() {
    // TODO(backend): PATCH status = out_for_delivery.
    _board.updateDelivery(
        delivery.copyWith(status: DeliveryStatus.outForDelivery));
  }

  void onMarkDeliveredPressed() {
    // TODO(backend): proof comes from the driver app; this is a manual
    // override by the owner.
    _board.updateDelivery(delivery.copyWith(
      status: DeliveryStatus.delivered,
      timeLabel: 'Just now',
    ));
  }

  /// Driver could not drop off: mark the attempt failed, then pick the
  /// reason and a new date.
  Future<void> onMarkFailedPressed() async {
    // TODO(backend): POST the failed attempt.
    _board.updateDelivery(delivery.copyWith(
      status: DeliveryStatus.failed,
      timeLabel: 'Today',
    ));
    await _board.onReschedule(delivery);
  }

  void onProofTap(int index) {
    // TODO(backend): open the full-size proof photo / signature.
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  // TODO(backend): pass the order id so the detail page loads it.
  void onOpenOrderPressed() => Get.toNamed(AppRoutes.orderDetail);
}
