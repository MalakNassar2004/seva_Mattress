import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/repositories/order_repository.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'order_models.dart';

/// Orders & Quotes (Orders tab of the owner shell). Orders are live from
/// Firestore. Quotes come in the next update.
class OrdersController extends GetxController {
  static const int ordersSegment = 0;
  static const int quotesSegment = 1;

  /// Status filter chips. null = All.
  static const List<OrderStatus?> statusFilters = [
    null,
    OrderStatus.newOrder,
    OrderStatus.inProduction,
    OrderStatus.ready,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  /// Quote filter chips. null = All.
  static const List<QuoteStatus?> quoteFilters = [
    null,
    QuoteStatus.sent,
    QuoteStatus.expiring,
    QuoteStatus.draft,
  ];

  // ---------------- State ----------------
  final segment = ordersSegment.obs;
  final statusFilterIndex = 0.obs;
  final quoteFilterIndex = 0.obs;

  final totalOrders = 0.obs;
  final totalQuotes = 0.obs;
  final statusCounts = <OrderStatus, int>{}.obs;

  final orders = <OrderItem>[].obs;
  final quotes = <QuoteItem>[].obs;

  final isLoading = true.obs;
  final loadError = RxnString();

  final _repo = OrderRepository();
  StreamSubscription<List<OrderItem>>? _sub;

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
    _sub = _repo.watchOrders().listen(
      (list) {
        orders.assignAll(list);
        totalOrders.value = list.length;
        final counts = <OrderStatus, int>{};
        for (final o in list) {
          counts[o.status] = (counts[o.status] ?? 0) + 1;
        }
        statusCounts.assignAll(counts);
        isLoading.value = false;
        loadError.value = null;
      },
      onError: (Object e) {
        isLoading.value = false;
        loadError.value = describeCustomerError(e);
        _showMessage('Could not load orders', describeCustomerError(e));
      },
    );
  }

  List<OrderItem> get visibleOrders {
    final s = statusFilters[statusFilterIndex.value];
    return s == null ? orders : orders.where((o) => o.status == s).toList();
  }

  List<QuoteItem> get visibleQuotes {
    final s = quoteFilters[quoteFilterIndex.value];
    return s == null ? quotes : quotes.where((q) => q.status == s).toList();
  }

  // ---------------- Actions ----------------
  void selectSegment(int i) => segment.value = i;

  void selectStatusFilter(int i) => statusFilterIndex.value = i;

  void selectQuoteFilter(int i) => quoteFilterIndex.value = i;

  void onSearchPressed() {
    // TODO: order search (number, customer, phone).
  }

  void onFiltersPressed() {
    // TODO(design): advanced filters (date range, rep, store) not designed.
  }

  void _quotesSoon() => _showMessage(
        'Not available yet',
        'Quotes will be available in the next update.',
      );

  void onQuoteSend(QuoteItem quote) => _quotesSoon();

  void onQuoteEdit(QuoteItem quote) => _quotesSoon();

  void onConvertToOrder(QuoteItem quote) => _quotesSoon();

  /// Kept for older code: the list is live, so nothing to do.
  void updateOrderStatus(String number, OrderStatus status) {}

  // ---------------- Navigation ----------------
  /// Orders is a tab, so "back" returns to the Home tab.
  void onBackPressed() => OwnerNav.goToTab(OwnerShellController.homeTab);

  void onOrderTap(OrderItem order) =>
      Get.toNamed(AppRoutes.orderDetail, arguments: order);

  void onCreatePressed() => Get.toNamed(
        AppRoutes.orderForm,
        arguments: segment.value == quotesSegment ? 'quote' : 'order',
      );

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}