import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import '../purchase_orders/procurement_store.dart';
import 'supplier_models.dart';
import 'suppliers_mock.dart';

enum SupplierFilter { all, openPos, net30, preferred }

extension SupplierFilterLabel on SupplierFilter {
  String get label => switch (this) {
        SupplierFilter.all => 'All Suppliers',
        SupplierFilter.openPos => 'With Open POs',
        SupplierFilter.net30 => 'Net 30',
        SupplierFilter.preferred => 'Preferred',
      };
}

/// Suppliers list (owner). Opened from the More tab.
/// UI state only. Backend wiring is marked with TODO(backend).
class SuppliersController extends GetxController {
  final store = ProcurementStore.to;

  // ---------------- Mock data ----------------
  // TODO(backend): load the ledger summary from the API.
  static const double totalSpendYtd = SuppliersMock.totalSpendYtd;
  static const String spendTrend = SuppliersMock.spendTrend;
  static const String avgLeadTime = SuppliersMock.avgLeadTime;

  // ---------------- State ----------------
  final query = ''.obs;
  final filter = SupplierFilter.all.obs;
  final spendHidden = false.obs;

  int openPosOf(Supplier s) => store.openOrdersOf(s.id).length;

  double openValueOf(Supplier s) =>
      store.openOrdersOf(s.id).fold(0, (sum, o) => sum + o.openValue);

  int get openPoCount => store.orders.where((o) => o.isOpen).length;

  int countFor(SupplierFilter f) =>
      store.suppliers.where((s) => _matches(s, f)).length;

  bool _matches(Supplier s, SupplierFilter f) => switch (f) {
        SupplierFilter.all => true,
        SupplierFilter.openPos => openPosOf(s) > 0,
        SupplierFilter.net30 => s.terms == 'Net 30',
        SupplierFilter.preferred => s.preferred,
      };

  List<Supplier> get visible {
    final q = query.value.trim().toLowerCase();
    return store.suppliers.where((s) {
      if (!_matches(s, filter.value)) return false;
      if (q.isEmpty) return true;
      return '${s.name} ${s.contact} ${s.category} ${s.city} ${s.phone}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  // ---------------- Actions ----------------
  void onSearchChanged(String v) => query.value = v;
  void selectFilter(SupplierFilter f) => filter.value = f;
  void toggleSpendHidden() => spendHidden.toggle();

  void onFiltersPressed() {
    // TODO(design): advanced supplier filters (category, lead time).
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onSupplierTap(Supplier s) =>
      Get.toNamed(AppRoutes.supplierDetail, arguments: s.id);

  void onAddPressed() => Get.toNamed(AppRoutes.supplierForm);

  void onOpenPosPressed() => Get.toNamed(AppRoutes.purchaseOrders);

  void onNavTap(int index) => OwnerNav.goToTab(index);
}
