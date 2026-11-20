import 'dart:async';

import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/repositories/deliveries_repository.dart';
import 'package:seva_mattress/data/repositories/order_repository.dart';
import 'package:seva_mattress/modules/orders/order_models.dart'
    show fmtOrderDate;
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import 'assign_driver_sheet.dart';
import 'deliveries_mock.dart';
import 'delivery_models.dart';
import 'reschedule_sheet.dart';

/// Deliveries board (owner). The deliveries are the orders that have a
/// delivery date (or that are Ready and wait for one). Opened from More.
///
/// Real: the list, the days, the status changes and the dates.
/// Not built yet: drivers, the route map and the proof of delivery.
class DeliveriesController extends GetxController {
  static const int listMode = 0;
  static const int routeMode = 1;

  static List<DispatchDay> get days => DeliveriesMock.days;
  static const int todayIndex = DeliveriesMock.todayIndex;

  final _repo = DeliveriesRepository();
  final _orders = OrderRepository();

  final deliveries = <Delivery>[].obs;
  final isLoading = true.obs;
  final busy = false.obs;

  // ---------------- State ----------------
  final selectedDay = todayIndex.obs;
  final statusFilter = Rxn<DeliveryStatus>();
  final viewMode = listMode.obs;

  StreamSubscription<List<Delivery>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repo
        .watchDeliveries(
          firstDay: DeliveriesMock.firstDay,
          dayCount: DeliveriesMock.dayCount,
          todayIndex: todayIndex,
        )
        .listen(
      (list) {
        deliveries.assignAll(list);
        isLoading.value = false;
      },
      onError: (Object e) {
        isLoading.value = false;
        _toast('Could not load the deliveries', describeCustomerError(e));
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  DispatchDay get day => days[selectedDay.value];

  List<Delivery> get dayDeliveries =>
      deliveries.where((d) => d.dayIndex == selectedDay.value).toList();

  /// Cards shown for the selected day and status filter, in dispatch order:
  /// out for delivery, scheduled, pending, delivered, failed.
  List<Delivery> get visible {
    final f = statusFilter.value;
    final list =
        dayDeliveries.where((d) => f == null || d.status == f).toList();
    const order = [
      DeliveryStatus.outForDelivery,
      DeliveryStatus.scheduled,
      DeliveryStatus.pending,
      DeliveryStatus.delivered,
      DeliveryStatus.failed,
    ];
    list.sort(
        (a, b) => order.indexOf(a.status).compareTo(order.indexOf(b.status)));
    return list;
  }

  /// Stops drawn on the route view (not used while the map is not built).
  List<Delivery> get routeStops => dayDeliveries
      .where((d) =>
          d.status == DeliveryStatus.outForDelivery ||
          d.status == DeliveryStatus.scheduled)
      .toList();

  /// Count on the summary chips, for the selected day.
  int countFor(DeliveryStatus s) =>
      dayDeliveries.where((d) => d.status == s).length;

  Delivery? byId(String id) => deliveries.firstWhereOrNull((d) => d.id == id);

  // ---------------- Actions ----------------
  void selectDay(int i) {
    selectedDay.value = i;
    statusFilter.value = null;
  }

  /// Tapping the selected chip again clears the filter.
  void toggleStatusFilter(DeliveryStatus s) =>
      statusFilter.value = statusFilter.value == s ? null : s;

  void setViewMode(int m) => viewMode.value = m;

  void _toast(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  /// Marks the order Out for Delivery or Delivered. The status, the timeline
  /// and the audit log are written by the order repository.
  Future<void> setOrderStatus(Delivery d, String status) async {
    if (busy.value) return;
    busy.value = true;
    try {
      await _orders.changeStatus(
        orderId: d.id,
        newStatus: status,
        note: 'From Deliveries',
      );
      _toast(
        status == 'delivered' ? 'Marked as delivered' : 'Out for delivery',
        '${d.customer} · ${d.orderNumber}',
      );
    } catch (e) {
      _toast('Could not update', describeCustomerError(e));
    } finally {
      busy.value = false;
    }
  }

  /// Drivers are not built yet.
  Future<void> onAssignDriver(Delivery d) async {
    _toast(
      'Drivers are not available yet',
      'Driver accounts will be added in a later update.',
    );
  }

  /// Moves the delivery to another day.
  Future<void> onReschedule(Delivery d) async {
    final result = await RescheduleSheet.open(delivery: d);
    if (result == null) return;
    await _saveDate(d, result, failed: false);
  }

  /// The driver could not deliver: the reason is required, then a new day.
  /// The order goes back to Ready on the new day.
  Future<void> onReportFailed(Delivery d) async {
    final asFailed = d.copyWith(
      status: DeliveryStatus.failed,
      timeLabel: 'Today',
    );
    final result = await RescheduleSheet.open(delivery: asFailed);
    if (result == null) return;
    await _saveDate(d, result, failed: true);
  }

  /// "Schedule New Delivery": pick a Ready order that has no date, then a day.
  Future<void> onScheduleNewPressed() async {
    final pending =
        deliveries.where((d) => d.status == DeliveryStatus.pending).toList();
    if (pending.isEmpty) {
      _toast(
        'Nothing to schedule',
        'Orders that are Ready and have no delivery date appear here.',
      );
      return;
    }
    final result = await RescheduleSheet.openSchedule(pending);
    if (result == null) return;
    final d = byId(result.deliveryId);
    if (d != null) await _saveDate(d, result, failed: false);
  }

  Future<void> _saveDate(
    Delivery d,
    RescheduleResult r, {
    required bool failed,
  }) async {
    if (busy.value) return;
    busy.value = true;
    try {
      final date = DeliveriesMock.dateOf(r.dayIndex);
      final note = [
        if (r.reason.isNotEmpty) r.reason,
        if (r.note.isNotEmpty) r.note,
      ].join(' · ');
      await _repo.reschedule(
        orderId: d.id,
        date: date,
        title: failed
            ? 'Delivery failed, moved to ${fmtOrderDate(date)}'
            : 'Delivery scheduled for ${fmtOrderDate(date)}',
        note: note,
        backToReady: failed,
      );
      selectedDay.value = r.dayIndex;
      statusFilter.value = null;
      _toast(
        'Delivery scheduled',
        '${d.customer} · ${days[r.dayIndex].longLabel}',
      );
    } catch (e) {
      _toast('Could not save the date', describeCustomerError(e));
    } finally {
      busy.value = false;
    }
  }

  void onCallDriver(Driver driver) {
    _toast('Drivers are not available yet', 'Coming in a later update.');
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