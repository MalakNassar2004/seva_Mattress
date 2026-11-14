import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_nav.dart';
import '../suppliers/supplier_models.dart';
import 'po_mock.dart';
import 'po_models.dart';
import 'procurement_store.dart';
import 'receive_goods_sheet.dart';

/// Purchase Orders list (owner). Opened from More or a supplier.
/// Arguments: a PO number to search for (optional).
/// UI state only. Backend wiring is marked with TODO(backend).
class PurchaseOrdersController extends GetxController {
  final store = ProcurementStore.to;

  /// Tabs. null = All.
  static const List<PoStatus?> tabs = [
    null,
    PoStatus.draft,
    PoStatus.ordered,
    PoStatus.partial,
    PoStatus.received,
  ];

  static const String openValueTrend = PoMock.openValueTrend;

  // ---------------- State ----------------
  /// Opens on Ordered like the design.
  final tabIndex = 2.obs;
  final query = ''.obs;
  final valueHidden = false.obs;
  late final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String) {
      // Opened for one PO: show it whatever its status.
      tabIndex.value = 0;
      searchController.text = arg;
      query.value = arg;
    }
  }

  double get openValue =>
      store.orders.where((o) => o.isOpen).fold(0, (s, o) => s + o.openValue);

  int get activeCount => store.orders.where((o) => o.isOpen).length;
  int get awaitingCount =>
      store.orders.where((o) => o.status == PoStatus.ordered).length;
  int get partialCount =>
      store.orders.where((o) => o.status == PoStatus.partial).length;

  int countFor(PoStatus? s) => s == null
      ? store.orders.length
      : store.orders.where((o) => o.status == s).length;

  Supplier? supplierOf(PurchaseOrder o) => store.supplier(o.supplierId);

  List<PurchaseOrder> get visible {
    final s = tabs[tabIndex.value];
    final q = query.value.trim().toLowerCase();
    return store.orders.where((o) {
      if (s != null && o.status != s) return false;
      if (q.isEmpty) return true;
      final sup = supplierOf(o)?.name ?? '';
      final skus = o.lines.map((l) => '${l.sku} ${l.name}').join(' ');
      return '${o.number} $sup $skus'.toLowerCase().contains(q);
    }).toList();
  }

  // ---------------- Actions ----------------
  void selectTab(int i) => tabIndex.value = i;
  void onSearchChanged(String v) => query.value = v;
  void toggleValueHidden() => valueHidden.toggle();

  void onScanPressed() {
    // TODO(backend): scan a packing slip / PO barcode.
  }

  void onRefreshPressed() {
    // TODO(backend): reload POs from the API.
  }

  void onArchivePressed() {
    // TODO(design): archived POs not designed yet.
  }

  void onViewFreightPressed(PurchaseOrder o) {
    // TODO(backend): open the carrier tracking page.
    Get.snackbar('Freight', '${o.number} · ${o.freight ?? 'Awaiting pickup'}',
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.local_shipping_outlined));
  }

  Future<void> onReceivePressed(PurchaseOrder o) async {
    final result = await ReceiveGoodsSheet.open(o);
    if (result == null) return;
    // TODO(backend): POST the receipt; the API increments on-hand stock.
    store.saveOrder(result.order);
    if (result.draft) {
      Get.snackbar('Draft saved', 'Receiving progress for ${o.number} saved',
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.save_outlined));
      return;
    }
    tabIndex.value = tabs.indexOf(result.order.status);
    showDarkToast(
      'Inventory updated: +${result.units} units added to '
      '${result.location.label} stock',
    );
  }

  void onCardTap(PurchaseOrder o) {
    switch (o.status) {
      case PoStatus.draft:
        onResumePressed(o);
      case PoStatus.ordered:
      case PoStatus.partial:
        onReceivePressed(o);
      case PoStatus.received:
        Get.snackbar(
          '${o.number} received',
          '${o.receivedOn ?? formatPoDate(o.expected)}'
              '${o.invoice == null ? '' : ' · Invoice ${o.invoice}'}',
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.inventory_outlined),
        );
    }
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onResumePressed(PurchaseOrder o) =>
      Get.toNamed(AppRoutes.poForm, arguments: {'number': o.number});

  void onCreatePressed() => Get.toNamed(AppRoutes.poForm);

  void onNavTap(int index) => OwnerNav.goToTab(index);

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
