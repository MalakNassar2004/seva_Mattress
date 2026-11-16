import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/money.dart';
import '../approvals/approvals_store.dart';
import '../audit/audit_models.dart';
import '../audit/audit_store.dart';
import '../deliveries/deliveries_mock.dart';
import '../deliveries/delivery_models.dart';
import '../inventory/inventory_mock.dart';
import '../owner_shell/owner_nav.dart';
import '../owner_shell/owner_shell_controller.dart';
import '../sales/sales_store.dart';

/// Owner Home (dashboard). Lives in the Home tab of the owner shell, so its
/// controller is registered by OwnerShellBinding.
/// UI state only. Backend wiring is marked with TODO(backend).
class HomeController extends GetxController {
  final sales = SalesStore.to;
  final approvals = ApprovalsStore.to;
  final audit = AuditStore.to;

  static const periods = [
    SalesPeriod.today,
    SalesPeriod.week,
    SalesPeriod.month,
  ];

  // ---------------- State ----------------
  final period = SalesPeriod.today.obs;
  final hidden = false.obs;
  final loading = true.obs;

  // TODO(backend): listen to real connectivity changes.
  final online = true.obs;

  @override
  void onReady() {
    super.onReady();
    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    // TODO(backend): GET /dashboard?period=...
    await Future<void>.delayed(const Duration(milliseconds: 500));
    loading.value = false;
  }

  // ---------------- Derived ----------------
  SalesFilter get _filter => SalesFilter(range: period.value.range());

  SalesStats get stats => sales.stats(_filter);

  /// Net sales change vs the previous period, in percent (null = no base).
  double? get changePct {
    final prev = sales.stats(_filter.previous).net;
    if (prev == 0) return null;
    return (stats.net - prev) / prev * 100;
  }

  /// Running net sales for the sparkline.
  List<double> get spark {
    var sum = 0.0;
    return [for (final b in sales.buckets(_filter)) sum += b.sales - b.refunds];
  }

  int get lowStockCount =>
      InventoryMock.lowStockCount + InventoryMock.outOfStockCount;

  int get failedDeliveries => DeliveriesMock.deliveries
      .where((d) => d.status == DeliveryStatus.failed)
      .length;

  List<AuditEvent> get recent => audit.events.take(4).toList();

  String money(double v) => hidden.value ? '\$ ••••' : formatCad(v);

  String get greeting {
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'morning'
        : h < 17
        ? 'afternoon'
        : 'evening';
    return 'Good $part, Owner';
  }

  // ---------------- Actions ----------------
  void selectPeriod(int i) {
    period.value = periods[i];
    _load();
  }

  void toggleHidden() => hidden.toggle();

  Future<void> onRetry() async {
    online.value = true;
    await _load();
  }

  // ---------------- Navigation ----------------
  void onApprovals() => Get.toNamed(AppRoutes.approvals);
  void onLowStock() => OwnerNav.goToTab(OwnerShellController.inventoryTab);
  void onFailedDeliveries() => Get.toNamed(AppRoutes.deliveries);
  void onReports() => OwnerNav.goToTab(OwnerShellController.reportsTab);
  void onAuditLog() => Get.toNamed(AppRoutes.auditLog);

  void onAddProduct() => Get.toNamed(AppRoutes.productAdd);
  void onAddEmployee() => Get.toNamed(AppRoutes.staffForm);
  void onCreatePo() => Get.toNamed(AppRoutes.poForm);
  void onExport() => Get.toNamed(AppRoutes.exports);
}
