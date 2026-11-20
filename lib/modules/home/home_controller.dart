import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';
import 'package:seva_mattress/app/utils/names.dart';
import 'package:seva_mattress/data/repositories/audit_repository.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/home_repository.dart';
import 'package:seva_mattress/data/repositories/product_repository.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import 'package:seva_mattress/modules/orders/order_models.dart'
    show OrderStatus;
import 'package:seva_mattress/modules/products/product_item.dart'
    show StockStatus;
import '../../app/routes/app_routes.dart';
import '../../app/utils/money.dart';
import '../audit/audit_models.dart';
import '../customers/customer_form_sheet.dart';
import '../owner_shell/owner_nav.dart';
import '../owner_shell/owner_shell_controller.dart';
import '../sales/sales_models.dart' show PayMethod;
import '../sales/sales_store.dart'
    show SalesPeriod, SalesPeriodInfo, SalesStats;

/// Owner Home (dashboard). Lives in the Home tab of the owner shell, so its
/// controller is registered by OwnerShellBinding.
///
/// Everything here is live from Firestore: the orders, the payments, the
/// products and the audit log. Refunds, discounts and approvals are not built
/// yet, so they show zero.
class HomeController extends GetxController {
  static const periods = [
    SalesPeriod.today,
    SalesPeriod.week,
    SalesPeriod.month,
  ];

  final _home = HomeRepository();
  final _products = ProductRepository();
  final _audit = AuditRepository();

  // ---------------- State ----------------
  final period = SalesPeriod.today.obs;
  final hidden = false.obs;
  final loading = true.obs;
  final online = true.obs;

  final orders = <HomeOrder>[].obs;
  final events = <AuditEvent>[].obs;
  final methodCents = <PayMethod, int>{}.obs;
  final _lowStock = 0.obs;

  final userName = ''.obs;
  final storeName = 'Seva Mattress'.obs;

  StreamSubscription<List<HomeOrder>>? _ordersSub;
  StreamSubscription<dynamic>? _productsSub;
  StreamSubscription<List<AuditEvent>>? _auditSub;

  String _methodsKey = '';
  int _methodsToken = 0;

  @override
  void onInit() {
    super.onInit();
    _listenOrders();

    _productsSub = _products.watchProducts().listen(
      (list) {
        _lowStock.value = list
            .where((p) => p.isActive && p.status != StockStatus.inStock)
            .length;
      },
      onError: (Object _) {},
    );

    // Only the owner can read the audit log.
    _auditSub = _audit.watchEvents().listen(
      (list) => events.assignAll(list),
      onError: (Object _) {},
    );

    ever(orders, (_) => _loadMethods());
    ever(period, (_) => _loadMethods());
    _loadProfile();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _productsSub?.cancel();
    _auditSub?.cancel();
    super.onClose();
  }

  void _listenOrders() {
    _ordersSub?.cancel();
    _ordersSub = _home.watchOrders().listen(
      (list) {
        orders.assignAll(list);
        loading.value = false;
        online.value = true;
      },
      onError: (Object _) {
        loading.value = false;
        online.value = false;
      },
    );
  }

  Future<void> _loadProfile() async {
    try {
      final user = await SessionService().loadCurrentUser();
      if (user != null) userName.value = user.name;
    } catch (_) {}
    try {
      final company = await CompanyRepository().load();
      storeName.value = company.name;
    } catch (_) {}
  }

  // ---------------- Dates ----------------
  DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _today => _dayOf(DateTime.now());

  int get _days => switch (period.value) {
        SalesPeriod.today => 1,
        SalesPeriod.week => 7,
        _ => 30,
      };

  /// The selected period, or the one just before it (same length).
  DateTimeRange _range({bool previous = false}) {
    final t = _today;
    final n = _days;
    if (!previous) {
      return DateTimeRange(
        start: DateTime(t.year, t.month, t.day - (n - 1)),
        end: t,
      );
    }
    return DateTimeRange(
      start: DateTime(t.year, t.month, t.day - (2 * n - 1)),
      end: DateTime(t.year, t.month, t.day - n),
    );
  }

  bool _inRange(DateTime at, DateTimeRange r) {
    final d = _dayOf(at);
    return !d.isBefore(r.start) && !d.isAfter(r.end);
  }

  int _daysBetween(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day)
          .difference(DateTime.utc(a.year, a.month, a.day))
          .inDays;

  // ---------------- Figures ----------------
  SalesStats _statsFor(DateTimeRange r) {
    final st = SalesStats();
    for (final o in orders) {
      if (!o.counts || !_inRange(o.at, r)) continue;
      st.sales++;
      st.units += o.units;
           st.gross += o.subtotalCents / 100;
      st.discounts += o.discountCents / 100;
      if (o.refundedCents > 0) {
        st.refundCount++;
        // Refunds are stored with tax: shown before tax, like in Reports.
        final share =
            o.totalCents == 0 ? 0.0 : o.refundedCents / o.totalCents;
        st.refunds += (o.subtotalCents - o.discountCents) * share / 100;
      }
      st.taxes += o.taxCents / 100;
      st.collected += o.paidCents / 100;
      st.owing += o.balanceCents / 100;
    }
    return st;
  }

  SalesStats get stats {
    final st = _statsFor(_range());
    for (final m in PayMethod.values) {
      st.byMethod[m] = (methodCents[m] ?? 0) / 100;
    }
    return st;
  }

  /// GST and PST collected in the selected period, each on its own.
  (double, double) get _taxSplit {
    final r = _range();
    var gst = 0;
    var pst = 0;
    for (final o in orders) {
      if (!o.counts || !_inRange(o.at, r)) continue;
      gst += o.gstCents;
      pst += o.pstCents;
    }
    return (gst / 100, pst / 100);
  }

  String get taxSplitLabel {
    final (gst, pst) = _taxSplit;
    return 'GST ${money(gst)} · PST ${money(pst)}';
  }

  /// Net sales change vs the previous period, in percent (null = no base).
  double? get changePct {
    final prev = _statsFor(_range(previous: true)).net;
    if (prev == 0) return null;
    return (stats.net - prev) / prev * 100;
  }

  /// Running net sales for the sparkline (hours for one day, else days).
  List<double> get spark {
    final r = _range();
    final hourly = _days == 1;
    final n = hourly ? 12 : _days;
    final totals = List<double>.filled(n, 0);
    for (final o in orders) {
      if (!o.counts || !_inRange(o.at, r)) continue;
      final i = hourly ? o.at.hour ~/ 2 : _daysBetween(r.start, o.at);
      if (i >= 0 && i < n) {
        totals[i] += (o.subtotalCents - o.discountCents) / 100;
      }    }
    var sum = 0.0;
    return [for (final t in totals) sum += t];
  }

  bool get hasPayments => methodCents.values.fold<int>(0, (a, b) => a + b) > 0;

  /// Reads the payments of the orders of the period (at most 80 orders),
  /// only when something changed.
  Future<void> _loadMethods() async {
    final r = _range();
    final picked = [
      for (final o in orders)
        if (o.counts && o.paidCents > 0 && _inRange(o.at, r)) o,
    ].take(80).toList();

    final key = '${period.value.name}|'
        '${[for (final o in picked) '${o.id}:${o.paidCents}'].join(',')}';
    if (key == _methodsKey) return;
    _methodsKey = key;

    final token = ++_methodsToken;
    try {
      final totals = await _home.methodTotals([for (final o in picked) o.id]);
      if (token != _methodsToken) return;
      methodCents.assignAll(totals);
    } catch (_) {
      _methodsKey = ''; // try again on the next change
    }
  }

  // ---------------- Needs your attention ----------------
  /// Approvals are not built yet.
  int get pendingApprovals => 0;

  int get lowStockCount => _lowStock.value;

  /// Orders with a balance whose next payment date has passed.
  int get overdueCount => orders
      .where((o) =>
          o.counts &&
          o.balanceCents > 0 &&
          o.nextPaymentDate != null &&
          _dayOf(o.nextPaymentDate!).isBefore(_today))
      .length;

  /// Orders with a balance whose next payment is due in the next 7 days.
  int get dueSoonCount {
    final t = _today;
    final limit = DateTime(t.year, t.month, t.day + 7);
    return orders.where((o) {
      if (!o.counts || o.balanceCents <= 0 || o.nextPaymentDate == null) {
        return false;
      }
      final d = _dayOf(o.nextPaymentDate!);
      return !d.isBefore(t) && !d.isAfter(limit);
    }).length;
  }

  /// Orders to deliver today (not delivered yet).
  int get deliveriesTodayCount => orders
      .where((o) =>
          o.counts &&
          o.status != OrderStatus.delivered &&
          o.deliveryDate != null &&
          _dayOf(o.deliveryDate!) == _today)
      .length;

  List<AuditEvent> get recent => events.take(4).toList();

  // ---------------- Header ----------------
  String money(double v) => hidden.value ? '\$ ••••' : formatCad(v);

  String get initials {
    final n = userName.value.trim();
    return n.isEmpty ? 'OW' : initialsOf(n);
  }

  String get greeting {
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'morning'
        : h < 17
        ? 'afternoon'
        : 'evening';
    final first = userName.value.trim().split(' ').first;
    return 'Good $part, ${first.isEmpty ? 'Owner' : first}';
  }

  // ---------------- Actions ----------------
  void selectPeriod(int i) => period.value = periods[i];

  void toggleHidden() => hidden.toggle();

  Future<void> onRetry() async {
    loading.value = true;
    _listenOrders();
  }

  // ---------------- Navigation ----------------
  void onApprovals() => Get.toNamed(AppRoutes.approvals);
  void onLowStock() => OwnerNav.goToTab(OwnerShellController.inventoryTab);
  void onDeliveriesToday() => Get.toNamed(AppRoutes.deliveries);
  void onOrders() => OwnerNav.goToTab(OwnerShellController.ordersTab);
  void onReports() => OwnerNav.goToTab(OwnerShellController.reportsTab);
  void onAuditLog() => Get.toNamed(AppRoutes.auditLog);

  void onAddProduct() => Get.toNamed(AppRoutes.productAdd);
  Future<void> onAddCustomer() => CustomerFormSheet.open();
  void onExport() => Get.toNamed(AppRoutes.exports);
    void onAddEmployee() => Get.toNamed(AppRoutes.staffForm);
  void onCreatePo() => Get.toNamed(AppRoutes.poForm);
}