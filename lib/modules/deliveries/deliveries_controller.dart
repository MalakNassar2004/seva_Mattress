import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import 'assign_driver_sheet.dart';
import 'deliveries_mock.dart';
import 'delivery_models.dart';
import 'reschedule_sheet.dart';

/// Deliveries dispatch board (owner). Opened from More / Order detail.
/// UI state only. Backend wiring is marked with TODO(backend).
class DeliveriesController extends GetxController {
  static const int listMode = 0;
  static const int routeMode = 1;

  // ---------------- Mock data ----------------
  // TODO(backend): load days, counts, deliveries and drivers from the API.
  static const List<DispatchDay> days = DeliveriesMock.days;
  static const int todayIndex = DeliveriesMock.todayIndex;
  static const List<Driver> drivers = DeliveriesMock.drivers;

  final deliveries = <Delivery>[...DeliveriesMock.deliveries].obs;

  // ---------------- State ----------------
  final selectedDay = todayIndex.obs;
  final statusFilter = Rxn<DeliveryStatus>();
  final viewMode = listMode.obs;

  DispatchDay get day => days[selectedDay.value];

  List<Delivery> get dayDeliveries =>
      deliveries.where((d) => d.dayIndex == selectedDay.value).toList();

  /// Cards shown for the selected day and status filter, in dispatch order:
  /// out for delivery, scheduled, pending, failed, delivered.
  List<Delivery> get visible {
    final f = statusFilter.value;
    final list = dayDeliveries.where((d) => f == null || d.status == f).toList();
    const order = [
      DeliveryStatus.outForDelivery,
      DeliveryStatus.scheduled,
      DeliveryStatus.pending,
      DeliveryStatus.delivered,
      DeliveryStatus.failed,
    ];
    list.sort((a, b) =>
        order.indexOf(a.status).compareTo(order.indexOf(b.status)));
    return list;
  }

  /// Stops drawn on the route view (everything with a driver, not delivered).
  List<Delivery> get routeStops => dayDeliveries
      .where((d) =>
          d.status == DeliveryStatus.outForDelivery ||
          d.status == DeliveryStatus.scheduled)
      .toList();

  int countFor(DeliveryStatus s) {
    // TODO(backend): today's counts come from the whole fleet summary.
    if (selectedDay.value == todayIndex) {
      return DeliveriesMock.todayCounts[s] ?? 0;
    }
    return dayDeliveries.where((d) => d.status == s).length;
  }

  Delivery? byId(String id) => deliveries.firstWhereOrNull((d) => d.id == id);

  // ---------------- Actions ----------------
  void selectDay(int i) {
    selectedDay.value = i;
    statusFilter.value = null;
    // TODO(backend): fetch the deliveries of the selected day.
  }

  /// Tapping the selected chip again clears the filter.
  void toggleStatusFilter(DeliveryStatus s) =>
      statusFilter.value = statusFilter.value == s ? null : s;

  void setViewMode(int m) => viewMode.value = m;

  void updateDelivery(Delivery d) {
    final i = deliveries.indexWhere((x) => x.id == d.id);
    if (i >= 0) deliveries[i] = d;
  }

  Future<void> onAssignDriver(Delivery d) async {
    final result = await AssignDriverSheet.open(d);
    if (result == null) return;
    if (result.reschedule) {
      await onReschedule(d);
      return;
    }
    final driver = result.driver;
    if (driver == null) return;
    // TODO(backend): POST /deliveries/{id}/assign and notify the driver app.
    updateDelivery(d.copyWith(
      driver: driver,
      status: d.status == DeliveryStatus.pending
          ? DeliveryStatus.scheduled
          : d.status,
    ));
    Get.snackbar(
      'Driver assigned',
      '${driver.shortName} will deliver ${d.orderNumber}',
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.local_shipping_outlined),
    );
  }

  Future<void> onReschedule(Delivery d) async {
    final result = await RescheduleSheet.open(delivery: d);
    if (result == null) return;
    _applySchedule(d, result);
  }

  /// "Schedule New Delivery": pick a pending order, then a day and window.
  Future<void> onScheduleNewPressed() async {
    final pending =
        deliveries.where((d) => d.status == DeliveryStatus.pending).toList();
    if (pending.isEmpty) {
      Get.snackbar('Nothing to schedule',
          'Every ready order already has a delivery slot',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final result = await RescheduleSheet.openSchedule(pending);
    if (result == null) return;
    final d = byId(result.deliveryId);
    if (d != null) _applySchedule(d, result);
  }

  void _applySchedule(Delivery d, RescheduleResult r) {
    // TODO(backend): PATCH the delivery (and SMS the customer if
    // r.notifyCustomer).
    final note = [
      if (r.reason.isNotEmpty) 'Rescheduled: ${r.reason}',
      if (r.note.isNotEmpty) r.note,
    ];
    updateDelivery(d.copyWith(
      dayIndex: r.dayIndex,
      window: r.window,
      status: DeliveryStatus.scheduled,
      clearFailReason: true,
      driverNotes: [...d.driverNotes, ...note],
    ));
    selectedDay.value = r.dayIndex;
    statusFilter.value = null;
    Get.snackbar(
      'Delivery scheduled',
      '${d.customer} · ${days[r.dayIndex].longLabel} · ${r.window}',
      snackPosition: SnackPosition.BOTTOM,
      icon: const Icon(Icons.event_available),
    );
  }

  void onCallDriver(Driver driver) {
    // TODO(backend): launch the dialer (url_launcher) with driver.phone.
    Get.snackbar('Calling ${driver.name}', driver.phone,
        snackPosition: SnackPosition.BOTTOM, icon: const Icon(Icons.call));
  }

  void onTrackRoute(Delivery d) => viewMode.value = routeMode;

  void onFleetLivePressed() => viewMode.value = routeMode;

  void onStorePressed() {
    // TODO(design): store / floor switcher not designed yet.
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onDeliveryTap(Delivery d) =>
      Get.toNamed(AppRoutes.deliveryDetail, arguments: d.id);

  void onNavTap(int index) => OwnerNav.goToTab(index);
}
