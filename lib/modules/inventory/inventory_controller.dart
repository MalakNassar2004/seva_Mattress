import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'adjust_stock_sheet.dart';
import 'inventory_mock.dart';
import 'inventory_models.dart';

/// Inventory & Stock (Inventory tab of the owner shell).
/// UI state only. Backend wiring is marked with TODO(backend).
class InventoryController extends GetxController {
  // ---------------- State ----------------
  static const List<String> categories = [
    'All',
    'Mattresses',
    'Pillows',
    'Protectors',
    'Accessories',
  ];

  final tabIndex = 0.obs;
  final categoryIndex = 0.obs;
  final hideAmounts = false.obs;

  // ---------------- Mock data ----------------
  // TODO(backend): load the summary and the stock list from the API.
  static const double totalValue = InventoryMock.totalValue;
  static const String valueChange = InventoryMock.valueChange;
  static const int activeUnits = InventoryMock.activeUnits;
  static const int lowStockCount = InventoryMock.lowStockCount;
  static const int outOfStockCount = InventoryMock.outOfStockCount;
  static const List<String> tabLabels = InventoryMock.tabLabels;

  final items = <StockItem>[...InventoryMock.items].obs;

  // ---------------- Actions ----------------
  void selectTab(int i) => tabIndex.value = i;

  void selectCategory(int i) {
    categoryIndex.value = i;
    // TODO(backend): filter the stock list by category.
  }

  void toggleAmounts() => hideAmounts.value = !hideAmounts.value;

  void onSearchChanged(String query) {
    // TODO(backend): search by SKU, model or serial.
  }

  void onScanPressed() {
    // TODO(backend): open the barcode scanner and look up the scanned code.
  }

  void onSharePressed() {
    // TODO(backend): export / share the stock report (log it in the audit log).
  }

  void onItemTap(StockItem item) {
    // TODO(backend): open the stock item detail (not designed yet).
  }

  /// Bottom sheet, so its controller is created with Get.put in the sheet.
  void onAdjustStockPressed() {
    Get.bottomSheet(
      const AdjustStockSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  // ---------------- Navigation ----------------
  /// Inventory is a tab, so "back" returns to the Home tab.
  void onBackPressed() => OwnerNav.goToTab(OwnerShellController.homeTab);

  /// Temporary link to the Products catalogue.
  // TODO(design): replace with the real entry point when it is designed.
  void onProductsPressed() => Get.toNamed(AppRoutes.products);
}
