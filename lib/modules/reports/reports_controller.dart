import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/dates.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/page_widgets.dart';
import '../owner_shell/owner_nav.dart';
import '../owner_shell/owner_shell_controller.dart';
import '../sales/sales_models.dart';
import '../sales/sales_store.dart';
import 'report_export_sheet.dart';

enum ChartMode { sales, profit, refunds }

extension ChartModeLabel on ChartMode {
  String get label => switch (this) {
    ChartMode.sales => 'Sales',
    ChartMode.profit => 'Profit',
    ChartMode.refunds => 'Refunds',
  };
}

/// Sales Reports. Lives in the Reports tab of the owner shell, so its
/// controller is registered by OwnerShellBinding.
/// UI state only. Backend wiring is marked with TODO(backend).
class ReportsController extends GetxController {
  final store = SalesStore.to;

  static const SalesPeriod defaultPeriod = SalesPeriod.week;

  // ---------------- State ----------------
  final period = defaultPeriod.obs;
  final customRange = Rxn<DateTimeRange>();
  final type = Rxn<ProductType>();
  final method = Rxn<PayMethod>();
  final chartMode = ChartMode.sales.obs;
  final selectedBar = RxnInt();
  final profitHidden = true.obs;
  final loading = false.obs;

  // ---------------- Derived ----------------
  SalesFilter get filter => SalesFilter(
    range: period.value.range(custom: customRange.value),
    type: type.value,
    method: method.value,
  );

  SalesStats get stats => store.stats(filter);
  List<SalesBucket> get buckets => store.buckets(filter);
  List<ProductTotal> get topProducts => store.topProducts(filter);

  bool get hasFilters =>
      period.value != defaultPeriod ||
      type.value != null ||
      method.value != null;

  String get periodText {
    final r = filter.range;
    if (r.start == r.end) return formatDate(r.start);
    return '${formatShortDate(r.start)} – ${formatDate(r.end)}';
  }

  double bucketValue(SalesBucket b) => switch (chartMode.value) {
    ChartMode.sales => b.sales,
    ChartMode.profit => b.profit < 0 ? 0 : b.profit,
    ChartMode.refunds => b.refunds,
  };

  /// Bar selected by default: the highest one.
  int? get activeBar {
    final list = buckets;
    if (list.isEmpty) return null;
    final sel = selectedBar.value;
    if (sel != null && sel < list.length) return sel;
    var best = 0;
    for (var i = 1; i < list.length; i++) {
      if (bucketValue(list[i]) > bucketValue(list[best])) best = i;
    }
    return best;
  }

  String tooltipOf(int i) {
    final b = buckets[i];
    return '${b.label}: ${formatCad(bucketValue(b), decimals: 0)}';
  }

  // ---------------- Actions ----------------
  Future<void> _reload() async {
    selectedBar.value = null;
    loading.value = true;
    // TODO(backend): GET /reports/sales with the filters.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    loading.value = false;
  }

  Future<void> selectPeriod(SalesPeriod p) async {
    if (p == SalesPeriod.custom) {
      final picked = await showDateRangeSheet(initial: customRange.value);
      if (picked == null) return;
      customRange.value = picked;
    }
    period.value = p;
    _reload();
  }

  void selectType(ProductType? t) {
    type.value = t;
    _reload();
  }

  void selectMethod(PayMethod? m) {
    method.value = m;
    _reload();
  }

  void clearAll() {
    period.value = defaultPeriod;
    customRange.value = null;
    type.value = null;
    method.value = null;
    _reload();
  }

  void selectChartMode(int i) {
    chartMode.value = ChartMode.values[i];
    selectedBar.value = null;
  }

  void selectBar(int i) => selectedBar.value = i;
  void toggleProfit() => profitHidden.toggle();

  Future<void> onExport() => ReportExportSheet.open(
    title: 'Sales report (${period.value.label})',
    periodText: periodText,
  );

  // ---------------- Navigation ----------------
  void onHome() => OwnerNav.goToTab(OwnerShellController.homeTab);
  void onTransactions() => Get.toNamed(AppRoutes.transactions);
}
