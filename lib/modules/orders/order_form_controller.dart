import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'order_models.dart';
import 'orders_controller.dart';
import 'orders_mock.dart';

/// Create Order / Quote, also used to edit a quote.
/// Arguments: 'order' | 'quote' (new) or a QuoteItem (edit).
/// UI state only. Backend wiring is marked with TODO(backend).
class OrderFormController extends GetxController {
  static const int orderType = 0;
  static const int quoteType = 1;

  static const double taxRate = 0.12;

  // ---------------- Mock data ----------------
  // TODO(backend): search customers / products from the API.
  static const List<(String, String, String)> customers = OrdersMock.customers;
  static const List<OrderLine> catalog = OrdersMock.catalog;

  final QuoteItem? editing =
      Get.arguments is QuoteItem ? Get.arguments as QuoteItem : null;

  bool get isEdit => editing != null;

  // ---------------- State ----------------
  late final type =
      (Get.arguments == 'quote' || isEdit ? quoteType : orderType).obs;
  final customerIndex = (-1).obs;

  /// Quantity per catalog index. 0 = not in the order.
  final qty = List<int>.filled(catalog.length, 0).obs;

  final isCustom = false.obs;
  final widthController = TextEditingController();
  final lengthController = TextEditingController();
  final angleController = TextEditingController();
  final thicknessController = TextEditingController();
  final notesController = TextEditingController();

  final depositController = TextEditingController();
  final deposit = 0.0.obs;

  /// Quote validity in days (7 / 14 / 30).
  static const List<int> validityOptions = [7, 14, 30];
  final validityIndex = 1.obs;

  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final q = editing;
    if (q != null) {
      customerIndex.value = customers.indexWhere((c) => c.$2 == q.customer);
      final i = catalog.indexWhere((l) => l.name.startsWith(q.product));
      if (i >= 0) qty[i] = 1;
    }
  }

  double get subtotal {
    var sum = 0.0;
    for (var i = 0; i < catalog.length; i++) {
      sum += catalog[i].price * qty[i];
    }
    return sum;
  }

  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;
  int get itemCount => qty.fold(0, (a, b) => a + b);

  // ---------------- Actions ----------------
  void selectType(int i) => type.value = i;

  void selectCustomer(int i) {
    customerIndex.value = i;
    error.value = null;
  }

  void increment(int i) {
    qty[i] = qty[i] + 1;
    error.value = null;
  }

  void decrement(int i) {
    if (qty[i] > 0) qty[i] = qty[i] - 1;
  }

  void toggleCustom(bool v) => isCustom.value = v;
  void selectValidity(int i) => validityIndex.value = i;

  void onDepositChanged(String v) =>
      deposit.value = double.tryParse(v.replaceAll(',', '')) ?? 0;

  void onAddCustomerPressed() {
    // TODO(design): quick-add customer sheet is not designed yet.
  }

  void onSave() {
    if (customerIndex.value < 0) {
      error.value = 'Select a customer';
      return;
    }
    if (itemCount == 0) {
      error.value = 'Add at least one item';
      return;
    }
    if (type.value == orderType && deposit.value > total + 0.004) {
      error.value = 'Deposit is more than the order total';
      return;
    }

    final c = customers[customerIndex.value];
    final firstIndex = qty.indexWhere((q) => q > 0);
    final product = catalog[firstIndex].name;
    final city = c.$3.split('·').last.trim();

    // TODO(backend): POST the order / quote and use the saved record.
    if (Get.isRegistered<OrdersController>()) {
      final orders = Get.find<OrdersController>();
      if (type.value == orderType) {
        orders.addOrder(OrderItem(
          number: '#ORD-${10893 + orders.orders.length}',
          product: product,
          customer: c.$2,
          city: city,
          status: OrderStatus.newOrder,
          isCustom: isCustom.value,
          dateLabel: 'Due date not set',
          total: total,
          paid: deposit.value,
          footerIcon: isCustom.value ? Icons.straighten : Icons.person_outline,
          footerText: isCustom.value ? _specSummary() : 'Showroom Rep: Owner',
        ));
      } else {
        final days = validityOptions[validityIndex.value];
        final until = DateTime.now().add(Duration(days: days));
        final quote = QuoteItem(
          number: editing?.number ?? '#QUO-${4020 + orders.quotes.length}',
          product: product,
          customer: c.$2,
          city: city,
          total: total,
          validUntil: _formatDate(until),
          note: '$itemCount item${itemCount == 1 ? '' : 's'}'
              '${isCustom.value ? ' · ${_specSummary()}' : ''}',
          status: editing?.status ?? QuoteStatus.draft,
        );
        orders.saveQuote(quote, replacing: editing);
      }
    }
    Get.back();
  }

  String _specSummary() {
    final w = widthController.text.trim();
    final l = lengthController.text.trim();
    final a = angleController.text.trim();
    final parts = <String>[
      if (w.isNotEmpty && l.isNotEmpty) '$w" × $l"',
      if (a.isNotEmpty) '$a° cut',
    ];
    return parts.isEmpty ? 'Custom specs pending' : parts.join(' · ');
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  @override
  void onClose() {
    widthController.dispose();
    lengthController.dispose();
    angleController.dispose();
    thicknessController.dispose();
    notesController.dispose();
    depositController.dispose();
    super.onClose();
  }
}
