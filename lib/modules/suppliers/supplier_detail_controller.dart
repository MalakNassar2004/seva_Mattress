import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../purchase_orders/po_models.dart';
import '../purchase_orders/procurement_store.dart';
import 'supplier_models.dart';
import 'suppliers_mock.dart';

/// Supplier detail. Opened with the supplier id as arguments.
/// UI state only. Backend wiring is marked with TODO(backend).
class SupplierDetailController extends GetxController {
  final store = ProcurementStore.to;

  final String id =
      Get.arguments is String ? Get.arguments as String : SuppliersMock.cascadia.id;

  // TODO(backend): load the supplier, its POs and invoices by id.
  Supplier get supplier => store.supplier(id) ?? SuppliersMock.cascadia;

  List<PurchaseOrder> get openOrders => store.openOrdersOf(id);

  List<PurchaseOrder> get history => store
      .ordersOf(id)
      .where((o) => o.status == PoStatus.received)
      .toList();

  /// Invoiced but unpaid (open POs that already have an invoice).
  double get outstanding => openOrders
      .where((o) => o.invoice != null)
      .fold(0, (s, o) => s + o.total);

  String? get outstandingDue =>
      openOrders.firstWhereOrNull((o) => o.invoiceDue != null)?.invoiceDue;

  // ---------------- Chart ----------------
  /// Index of the bar the owner tapped (shows its value). Defaults to the
  /// latest month.
  late final selectedBar = (supplier.costTrend.length - 1).obs;

  double get averageCost {
    final v = supplier.costTrend.map((p) => p.value).whereType<double>();
    return v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
  }

  /// Change from the first to the last month with data, in %.
  double get trendPct {
    final v = supplier.costTrend.map((p) => p.value).whereType<double>().toList();
    if (v.length < 2 || v.first == 0) return 0;
    return (v.last - v.first) / v.first * 100;
  }

  void selectBar(int i) {
    if (supplier.costTrend[i].value != null) selectedBar.value = i;
  }

  // ---------------- Actions ----------------
  void onCallPressed() {
    // TODO(backend): launch the dialer (url_launcher).
    Get.snackbar('Calling ${supplier.contact}', supplier.phone,
        snackPosition: SnackPosition.BOTTOM, icon: const Icon(Icons.call));
  }

  void onEmailPressed() {
    // TODO(backend): open the mail composer.
    Get.snackbar('Email', supplier.email,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.mail_outline));
  }

  void onCatalogPressed() {
    // TODO(backend): open the supplier price list PDF.
  }

  void onMorePressed() {
    // TODO(design): supplier actions (deactivate, merge) not designed.
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onEditPressed() => Get.toNamed(AppRoutes.supplierForm, arguments: id);

  void onCreatePoPressed() =>
      Get.toNamed(AppRoutes.poForm, arguments: {'supplierId': id});

  void onViewAllPressed() => Get.toNamed(AppRoutes.purchaseOrders);

  void onOrderTap(PurchaseOrder o) =>
      Get.toNamed(AppRoutes.purchaseOrders, arguments: o.number);
}
