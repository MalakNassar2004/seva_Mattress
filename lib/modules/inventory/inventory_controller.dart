import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart';
import 'package:seva_mattress/data/repositories/stock_repository.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import '../owner_shell/owner_shell_controller.dart';
import '../products/product_item.dart';
import '../scanner/scanner_view.dart';
import 'adjust_stock_controller.dart';
import 'adjust_stock_sheet.dart';
import 'inventory_mock.dart';
import 'inventory_models.dart';

/// Inventory & Stock (Inventory tab of the owner shell).
/// The stock list, the summary and the movements are live from Firestore.
class InventoryController extends GetxController {
  // ---------------- State ----------------
  static const List<String> categories = [
    'All',
    'Mattresses',
    'Pillows',
    'Protectors',
    'Accessories',
  ];

  /// Tabs: 0 = Stock, 1 = Movements, 2 = Low Stock.
  static const int movementsTab = 1;
  static const int lowTab = 2;

  final tabIndex = 0.obs;
  final categoryIndex = 0.obs;
  final hideAmounts = false.obs;

  // ---------------- Old design mock (not used any more) ----------------
  // TODO: delete together with inventory_mock.dart.
  static const double totalValue = InventoryMock.totalValue;
  static const String valueChange = InventoryMock.valueChange;
  static const int activeUnits = InventoryMock.activeUnits;
  static const int lowStockCount = InventoryMock.lowStockCount;
  static const int outOfStockCount = InventoryMock.outOfStockCount;
  static const List<String> tabLabels = InventoryMock.tabLabels;

  // ---------------- Live data ----------------
  final _productRepo = ProductRepository();
  final _stockRepo = StockRepository();

  /// What the Stock / Low Stock tab shows (after tab, category and search).
  final items = <StockItem>[].obs;

  /// Movements tab (owner only).
  final movements = <StockMovement>[].obs;
  final movementsError = RxnString();

  final isLoading = true.obs;
  final loadError = RxnString();

  /// true only for the owner (cost, value and movements are owner-only).
  final canViewCost = false.obs;

  // Live summary.
  final liveTotalValue = 0.0.obs;
  final liveActiveUnits = 0.obs;
  final liveLowStock = 0.obs;
  final liveOutOfStock = 0.obs;
  final liveProductCount = 0.obs;

  /// Number shown on the Low Stock tab (low + out of stock).
  int get lowTabCount => liveLowStock.value + liveOutOfStock.value;

  final List<ProductItem> _all = [];
  Map<String, double> _costs = {};
  String _query = '';
  StreamSubscription<List<ProductItem>>? _productsSub;
  StreamSubscription<Map<String, double>>? _costsSub;
  StreamSubscription<List<StockMovement>>? _movementsSub;

  @override
  void onInit() {
    super.onInit();
    _listenProducts();
    _listenOwnerData();
  }

  @override
  void onClose() {
    _productsSub?.cancel();
    _costsSub?.cancel();
    _movementsSub?.cancel();
    super.onClose();
  }

  void _listenProducts() {
    isLoading.value = true;
    _productsSub = _productRepo.watchProducts().listen(
          (list) {
        _all
          ..clear()
          ..addAll(list);
        isLoading.value = false;
        loadError.value = null;
        _rebuild();
      },
      onError: (Object e) {
        isLoading.value = false;
        loadError.value = describeError(e);
        _showError('Could not load stock', describeError(e));
      },
    );
  }

  /// Costs and movements are owner-only: other roles never even ask for them.
  Future<void> _listenOwnerData() async {
    try {
      final user = await SessionService().loadCurrentUser();
      if (user == null || !user.isOwner) return;
      canViewCost.value = true;

      _costsSub = _stockRepo.watchCosts().listen(
            (map) {
          _costs = map;
          _rebuild();
        },
        onError: (Object e) {
          canViewCost.value = false;
          _costs = {};
          _rebuild();
        },
      );

      _movementsSub = _stockRepo.watchMovements().listen(
            (list) {
          movements.assignAll(list);
          movementsError.value = null;
        },
        onError: (Object e) {
          movementsError.value = describeError(e);
        },
      );
    } catch (_) {
      // No owner data: the screen still works without values.
    }
  }

  StockItem _toStockItem(ProductItem p) {
    final available = p.available;
    final level = available <= 0
        ? StockLevel.out
        : available <= kLowStockThreshold
        ? StockLevel.low
        : StockLevel.ok;
    return StockItem(
      id: p.id,
      name: p.name,
      sku: p.sku,
      warehouse: p.units,
      showroom: p.showroomUnits,
      damaged: p.damagedUnits,
      category: p.category,
      cost: _costs[p.id] ?? 0,
      level: level,
      threshold: level == StockLevel.low ? kLowStockThreshold : null,
      reorderStatus: level == StockLevel.out && p.reorderPo != null
          ? 'Reorder status: PO ${p.reorderPo}'
          : null,
      showLocationIcons: true,
    );
  }

  /// Recomputes the summary and the visible list.
  void _rebuild() {
    var value = 0.0;
    var units = 0;
    var low = 0;
    var out = 0;
    for (final p in _all) {
      final available = p.available;
      units += available;
      if (available <= 0) {
        out++;
      } else if (available <= kLowStockThreshold) {
        low++;
      }
      value += (_costs[p.id] ?? 0) * available;
    }
    liveTotalValue.value = value;
    liveActiveUnits.value = units;
    liveLowStock.value = low;
    liveOutOfStock.value = out;
    liveProductCount.value = _all.length;

    final label = categories[categoryIndex.value];
    final q = _query.trim().toLowerCase();

    final list = _all
        .where((p) => label == 'All' || p.category == label)
        .where(
          (p) =>
      q.isEmpty ||
          [p.name, p.sku, p.model]
              .any((s) => s.toLowerCase().contains(q)),
    )
        .where(
          (p) =>
      tabIndex.value != lowTab || p.available <= kLowStockThreshold,
    )
        .toList();

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    items.assignAll(list.map(_toStockItem));
  }

  // ---------------- Actions ----------------
  void selectTab(int i) {
    tabIndex.value = i;
    // The search box starts empty on every tab (the view recreates it).
    _query = '';
    _rebuild();
  }

  void selectCategory(int i) {
    categoryIndex.value = i;
    _rebuild();
  }

  void toggleAmounts() => hideAmounts.value = !hideAmounts.value;

  void onSearchChanged(String query) {
    _query = query;
    _rebuild();
  }

  /// Scan a barcode: opens Adjust Stock for that product.
  Future<void> onScanPressed() => _scanAndAdjust();

  void onSharePressed() {
    // TODO(backend): export / share the stock report (log it in the audit log).
  }

  /// Tapping a stock card opens Adjust Stock for that product.
  void onItemTap(StockItem item) => _openAdjust(item);

  /// The big blue button: scan a barcode, then adjust that product.
  /// (To adjust without a barcode, tap the product card.)
  Future<void> onAdjustStockPressed() => _scanAndAdjust();

  Future<void> _scanAndAdjust() async {
    final raw = await ScannerView.scan();
    if (raw == null) return;
    final code = normalizeSku(raw);
    if (code.isEmpty) return;

    ProductItem? found;
    for (final p in _all) {
      if (normalizeSku(p.sku) == code) {
        found = p;
        break;
      }
    }
    if (found == null) {
      _showError('Not found', 'No product has the SKU $code.');
      return;
    }
    _openAdjust(_toStockItem(found));
  }

  /// Bottom sheet (not a route): its controller is created inside the sheet,
  /// and removed when the sheet closes so the next one starts fresh.
  void _openAdjust(StockItem item) {
    if (item.id.isEmpty) return;
    if (Get.isRegistered<AdjustStockController>()) {
      Get.delete<AdjustStockController>(force: true);
    }
    Get.bottomSheet(
      AdjustStockSheet(item: item, canViewCost: canViewCost.value),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    ).whenComplete(() {
      if (Get.isRegistered<AdjustStockController>()) {
        Get.delete<AdjustStockController>(force: true);
      }
    });
  }

  // ---------------- Navigation ----------------
  /// Inventory is a tab, so "back" returns to the Home tab.
  void onBackPressed() => OwnerNav.goToTab(OwnerShellController.homeTab);

  /// Temporary link to the Products catalogue.
  // TODO(design): replace with the real entry point when it is designed.
  void onProductsPressed() => Get.toNamed(AppRoutes.products);

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}