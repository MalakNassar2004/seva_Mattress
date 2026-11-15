import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import 'product_item.dart';

/// Products catalogue (/products, opened from the Inventory tab).
/// Data comes live from Firestore through ProductRepository.
class ProductsController extends GetxController {
  // ---------------- State ----------------
  /// Kept only so the existing view still compiles. It does NOT follow the
  /// real data: the real number is [totalCount].
  static const int totalSkus = 142;

  static const List<String> _categoryLabels = [
    'All',
    'Mattresses',
    'Pillows',
    'Protectors',
    'Accessories',
    'Custom-size',
  ];

  static const List<String> sortOptions = [
    'High stock first',
    'Low stock first',
    'Price: high to low',
    'Price: low to high',
    'Name A-Z',
  ];

  final _repo = ProductRepository();

  /// Category chips with live counts.
  final categories = <ProductCategory>[
    for (final label in _categoryLabels) ProductCategory(label, 0),
  ].obs;

  final selectedCategory = 0.obs;
  final sortLabel = 'High stock first'.obs;

  /// What the list shows (after category, search and sort).
  final products = <ProductItem>[].obs;

  /// Number of products in total.
  final totalCount = 0.obs;

  final isLoading = true.obs;
  final loadError = RxnString();

  final List<ProductItem> _all = [];
  String _query = '';
  StreamSubscription<List<ProductItem>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _listen() {
    isLoading.value = true;
    _sub = _repo.watchProducts().listen(
          (items) {
        _all
          ..clear()
          ..addAll(items);
        isLoading.value = false;
        loadError.value = null;
        _refresh();
      },
      onError: (Object e) {
        isLoading.value = false;
        loadError.value = describeError(e);
        _showError('Could not load products', describeError(e));
      },
    );
  }

  bool _inCategory(ProductItem p, String label) {
    switch (label) {
      case 'All':
        return true;
      case 'Custom-size':
        return p.customSize;
      default:
        return p.category == label;
    }
  }

  void _sort(List<ProductItem> list) {
    switch (sortLabel.value) {
      case 'Low stock first':
        list.sort((a, b) => a.units.compareTo(b.units));
        break;
      case 'Price: high to low':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Price: low to high':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Name A-Z':
        list.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      default: // High stock first
        list.sort((a, b) => b.units.compareTo(a.units));
    }
  }

  /// Rebuilds counts and the visible list from the full list.
  void _refresh() {
    totalCount.value = _all.length;

    categories.assignAll([
      for (final label in _categoryLabels)
        ProductCategory(
          label,
          _all.where((p) => _inCategory(p, label)).length,
        ),
    ]);

    final label = _categoryLabels[selectedCategory.value];
    final q = _query.trim().toLowerCase();

    final list = _all
        .where((p) => _inCategory(p, label))
        .where(
          (p) =>
      q.isEmpty ||
          [p.name, p.sku, p.model, p.size]
              .any((s) => s.toLowerCase().contains(q)),
    )
        .toList();

    _sort(list);
    products.assignAll(list);
  }

  // ---------------- Actions ----------------
  void selectCategory(int index) {
    selectedCategory.value = index;
    _refresh();
  }

  void selectSort(String label) {
    sortLabel.value = label;
    _refresh();
  }

  void onSearchChanged(String query) {
    _query = query;
    _refresh();
  }

  void onFilterPressed() {
    // TODO(backend): open the filters (not designed yet) and apply them.
  }

  /// Soft delete: the product is hidden but past sales are kept.
  void deleteProduct(ProductItem product) {
    _delete(product);
  }

  Future<void> _delete(ProductItem product) async {
    if (product.id.isEmpty) return;
    try {
      await _repo.softDelete(product);
    } catch (e) {
      _showError('Could not delete', describeError(e));
    }
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onAddProductPressed() => Get.toNamed(AppRoutes.productAdd);

  void onEditProduct(ProductItem product) =>
      Get.toNamed(AppRoutes.productEdit, arguments: product);

  void onNavTap(int index) => OwnerNav.goToTab(index);

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}