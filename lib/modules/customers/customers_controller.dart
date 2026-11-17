import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import 'customer_form_sheet.dart';
import 'customer_models.dart';

/// Customers list (opened from the More tab). Live from Firestore.
class CustomersController extends GetxController {
  // ---------------- State ----------------
  /// Index 1 is drawn as the amber "balance owing" chip.
  static const List<String> filters = [
    'All',
    'Balance Owing',
    'Recent',
  ];
  static const int balanceFilter = 1;
  static const int recentFilter = 2;

  final filterIndex = 0.obs;

  /// What the list shows (after filter and search).
  final customers = <CustomerItem>[].obs;

  /// Number of customers in total.
  final totalCount = 0.obs;

  final isLoading = true.obs;
  final loadError = RxnString();

  final _repo = CustomerRepository();
  final List<CustomerItem> _all = [];
  String _query = '';
  StreamSubscription<List<CustomerItem>>? _sub;

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
    _sub = _repo.watchCustomers().listen(
          (list) {
        _all
          ..clear()
          ..addAll(list);
        isLoading.value = false;
        loadError.value = null;
        _refresh();
      },
      onError: (Object e) {
        isLoading.value = false;
        loadError.value = describeCustomerError(e);
        _showMessage('Could not load customers', describeCustomerError(e));
      },
    );
  }

  /// Rebuilds the visible list from the full list.
  void _refresh() {
    totalCount.value = _all.length;

    final q = _query.trim().toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');

    var list = _all.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q) ||
          (digits.length >= 3 && c.phoneKey.contains(digits));
    }).toList();

    final f = filterIndex.value;
    if (f == balanceFilter) {
      list = list.where((c) => (c.balanceOwing ?? 0) > 0).toList();
    }

    if (f == recentFilter) {
      final now = DateTime.now();
      list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
    } else {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    customers.assignAll(list);
  }

  // ---------------- Actions ----------------
  void selectFilter(int i) {
    filterIndex.value = i;
    _refresh();
  }

  void onSearchChanged(String query) {
    _query = query;
    _refresh();
  }

  void onScanPressed() {
    // TODO(design): scanning a loyalty card is not defined yet.
  }

  /// Reloads the list (it is live, so this is rarely needed).
  Future<void> onSyncPressed() async {
    await _sub?.cancel();
    _listen();
  }

  Future<void> onAddCustomerPressed() async {
    final saved = await CustomerFormSheet.open();
    if (saved != null) {
      _showMessage('Saved', '${saved.name} was added.');
    }
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onCustomerTap(CustomerItem customer) =>
      Get.toNamed(AppRoutes.customerDetail, arguments: customer);

  void onNavTap(int index) => OwnerNav.goToTab(index);

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}