import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'order_models.dart';
import 'orders_mock.dart';

/// Orders & Quotes (Orders tab of the owner shell).
/// UI state only. Backend wiring is marked with TODO(backend).
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

  // ---------------- Mock data ----------------
  // TODO(backend): load orders, quotes and counts from the API.
  static const int totalOrders = OrdersMock.totalOrders;
  final totalQuotes = OrdersMock.totalQuotes.obs;
  static const Map<OrderStatus, int> statusCounts = OrdersMock.statusCounts;

  final orders = <OrderItem>[...OrdersMock.orders].obs;
  final quotes = <QuoteItem>[...OrdersMock.quotes].obs;

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

  void selectStatusFilter(int i) {
    statusFilterIndex.value = i;
    // TODO(backend): request the filtered list instead of filtering locally.
  }

  void selectQuoteFilter(int i) => quoteFilterIndex.value = i;

  void onSearchPressed() {
    // TODO(backend): open order search (number, customer, phone).
  }

  void onFiltersPressed() {
    // TODO(design): advanced filters (date range, rep, store) not designed.
  }

  void onQuoteSend(QuoteItem quote) {
    // TODO(backend): email / SMS the quote PDF to the customer.
    _replaceQuote(quote, quote.copyWith(status: QuoteStatus.sent));
    Get.snackbar(
      'Quote sent',
      '${quote.number} was sent to ${quote.customer}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void onQuoteEdit(QuoteItem quote) =>
      Get.toNamed(AppRoutes.orderForm, arguments: quote);

  /// Turns the quote into a new order and opens the Orders segment.
  void onConvertToOrder(QuoteItem quote) {
    // TODO(backend): POST /quotes/{id}/convert and use the returned order.
    final order = OrderItem(
      number: quote.number.replaceFirst('QUO', 'ORD'),
      product: quote.product,
      customer: quote.customer,
      city: quote.city,
      status: OrderStatus.newOrder,
      dateLabel: 'Due date not set',
      total: quote.total,
      paid: 0,
      footerIcon: Icons.swap_horiz,
      footerText: 'Converted from ${quote.number}',
    );
    quotes.remove(quote);
    totalQuotes.value = quotes.length;
    orders.insert(0, order);
    statusFilterIndex.value = 0;
    segment.value = ordersSegment;
  }

  void _replaceQuote(QuoteItem oldQ, QuoteItem newQ) {
    final i = quotes.indexOf(oldQ);
    if (i >= 0) quotes[i] = newQ;
  }

  /// Called by the Create Order form.
  void addOrder(OrderItem order) {
    orders.insert(0, order);
    statusFilterIndex.value = 0;
    segment.value = ordersSegment;
  }

  /// Called by the Create / Edit Quote form.
  void saveQuote(QuoteItem quote, {QuoteItem? replacing}) {
    final i = replacing == null ? -1 : quotes.indexOf(replacing);
    if (i >= 0) {
      quotes[i] = quote;
    } else {
      quotes.insert(0, quote);
    }
    totalQuotes.value = quotes.length;
    quoteFilterIndex.value = 0;
    segment.value = quotesSegment;
  }

  /// Called by the detail page when the status changes there.
  void updateOrderStatus(String number, OrderStatus status) {
    final i = orders.indexWhere((o) => o.number == number);
    if (i >= 0) orders[i] = orders[i].copyWith(status: status);
  }

  // ---------------- Navigation ----------------
  /// Orders is a tab, so "back" returns to the Home tab.
  void onBackPressed() => OwnerNav.goToTab(OwnerShellController.homeTab);

  // TODO(backend): pass the order id so the detail page loads it.
  void onOrderTap(OrderItem order) =>
      Get.toNamed(AppRoutes.orderDetail, arguments: order);

  void onCreatePressed() => Get.toNamed(
        AppRoutes.orderForm,
        arguments: segment.value == quotesSegment ? 'quote' : 'order',
      );
}
