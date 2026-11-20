import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_activity_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes/app_routes.dart';
import '../orders/order_models.dart';
import 'customer_form_sheet.dart';
import 'customer_models.dart';
import 'customer_note_sheet.dart';

/// Customer detail (owner view). Opened with the CustomerItem (from the
/// list) as arguments, then it follows the live customer, his orders and his
/// notes from Firestore.
class CustomerDetailController extends GetxController {
  final CustomerItem? _source =
      Get.arguments is CustomerItem ? Get.arguments as CustomerItem : null;

  final _customers = CustomerRepository();
  final _activity = CustomerActivityRepository();

  // ---------------- State ----------------
  /// 0 = Orders, 1 = Notes, 2 = Warranty & Care
  final tabIndex = 0.obs;
  final hideAmounts = false.obs;

  late final customer = Rxn<CustomerItem>(_source);
  final orders = <OrderItem>[].obs;
  final notes = <CustomerNote>[].obs;

  StreamSubscription<CustomerItem?>? _customerSub;
  StreamSubscription<List<OrderItem>>? _ordersSub;
  StreamSubscription<List<CustomerNote>>? _notesSub;

  @override
  void onInit() {
    super.onInit();
    final id = customer.value?.id ?? '';
    if (id.isEmpty) return;

    _customerSub = _customers.watchCustomer(id).listen(
      (c) {
        if (c != null) customer.value = c;
      },
      onError: _onError,
    );
    _ordersSub = _activity.watchOrders(id).listen(
          (list) => orders.assignAll(list),
      onError: _onError,
    );
    _notesSub = _activity.watchNotes(id).listen(
          (list) => notes.assignAll(list),
      onError: _onError,
    );
  }

  @override
  void onClose() {
    _customerSub?.cancel();
    _ordersSub?.cancel();
    _notesSub?.cancel();
    super.onClose();
  }

  void _onError(Object e) =>
      _showMessage('Could not load', describeCustomerError(e));

  // ---------------- What the screen shows ----------------
  String get name => customer.value?.name ?? '';
  String get city => customer.value?.city ?? '';
  String get address => customer.value?.address ?? '';
  bool get isVip => customer.value?.isVip ?? false;

  String get phoneDisplay {
    final p = customer.value?.phone ?? '';
    return p.isEmpty ? '—' : p;
  }

  String get emailDisplay {
    final e = customer.value?.email ?? '';
    return e.isEmpty ? '—' : e;
  }

  /// The note typed in the customer form (shown first in the Notes tab).
  String get profileNote => (customer.value?.notes ?? '').trim();

  /// "CUST-0001". A customer saved before numbers existed shows "—" until he
  /// is saved once (Edit, then Save).
  String get customerCode {
    final n = (customer.value?.number ?? '').trim();
    return n.isEmpty ? '—' : n;
  }

  List<String> get tabLabels => [
    'Orders (${orders.length})',
    'Notes (${notes.length + (profileNote.isEmpty ? 0 : 1)})',
    'Warranty & Care',
  ];

  // Cancelled orders are not counted.
  List<OrderItem> get _counted =>
      orders.where((o) => o.status != OrderStatus.cancelled).toList();

  int _cents(double v) => (v * 100).round();

  int get lifetimeOrders => _counted.length;

  int get openOrders =>
      _counted.where((o) => o.status != OrderStatus.delivered).length;

  /// Total of all his orders (cancelled ones excluded).
  double get totalSpent =>
      _counted.fold<int>(0, (a, o) => a + _cents(o.total)) / 100;

  /// What he still owes on all his orders.
  double get balance {
    final cents = _counted.fold<int>(0, (a, o) {
      final owing = _cents(o.total) - _cents(o.paid);
      return a + (owing > 0 ? owing : 0);
    });
    return cents / 100;
  }

  // ---------------- Actions ----------------
  void selectTab(int i) => tabIndex.value = i;

  void toggleAmounts() => hideAmounts.value = !hideAmounts.value;

  Future<void> onEditPressed() async {
    final c = customer.value;
    if (c == null || c.id.isEmpty) return;
    final saved = await CustomerFormSheet.open(editing: c);
    if (saved != null) {
      _showMessage('Saved', 'The customer was updated.');
    }
  }

  /// The address is part of the customer form.
  void onAddAddressPressed() => onEditPressed();

  void onMorePressed() {
    // TODO(design): customer actions menu is not designed yet.
  }

  /// +1 for a 10-digit Canada / US number, otherwise the full international
  /// number (the digits already include the country code).
  String? _dialNumber() {
    final key = customer.value?.phoneKey ?? '';
    if (key.isEmpty) return null;
    return key.length == 10 ? '+1$key' : '+$key';
  }

  Future<void> _open(Uri uri, String action) async {
    try {
      final ok = await launchUrl(uri);
      if (!ok) _showMessage('Not available', 'This device cannot $action.');
    } catch (_) {
      _showMessage('Not available', 'This device cannot $action.');
    }
  }

  void onCallPressed() {
    final n = _dialNumber();
    if (n == null) return;
    _open(Uri(scheme: 'tel', path: n), 'make phone calls');
  }

  void onSmsPressed() {
    final n = _dialNumber();
    if (n == null) return;
    _open(Uri(scheme: 'sms', path: n), 'send text messages');
  }

  void onEmailPressed() {
    final e = customer.value?.email ?? '';
    if (e.isEmpty) {
      _showMessage('No email', 'This customer has no email saved.');
      return;
    }
    _open(Uri(scheme: 'mailto', path: e), 'send emails');
  }

  /// Opens the order form with this customer already chosen.
  void onCreateOrderPressed() {
    final c = customer.value;
    if (c == null || c.id.isEmpty) return;
    Get.toNamed(AppRoutes.orderForm, arguments: c);
  }

  Future<void> onLogNotePressed() async {
    final c = customer.value;
    if (c == null || c.id.isEmpty) return;
    final saved = await CustomerNoteSheet.open(
      customerId: c.id,
      customerName: c.name,
    );
    if (saved == true) {
      tabIndex.value = 1;
      _showMessage('Saved', 'The note was added.');
    }
  }

  void onOrderTap(OrderItem order) =>
      Get.toNamed(AppRoutes.orderDetail, arguments: order);

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}