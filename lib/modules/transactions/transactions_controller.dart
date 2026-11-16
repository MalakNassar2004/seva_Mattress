import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import '../sales/sales_models.dart';
import '../sales/sales_store.dart';

/// Transactions list (owner). Opened from Reports.
/// UI state only. Backend wiring is marked with TODO(backend).
class TransactionsController extends GetxController {
  final store = SalesStore.to;

  // ---------------- State ----------------
  final query = ''.obs;

  /// null = All.
  final status = Rxn<SaleStatus>();

  List<Sale> get _searched {
    final q = query.value.trim().toLowerCase();
    final list = store.sales.where((s) {
      if (q.isEmpty) return true;
      return '${s.invoice} ${s.customer} ${s.cashier} '
              '${s.lines.map((l) => '${l.name} ${l.size}').join(' ')}'
          .toLowerCase()
          .contains(q);
    }).toList()..sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  int countFor(SaleStatus? s) =>
      _searched.where((x) => s == null || x.status == s).length;

  List<Sale> get visible => _searched
      .where((x) => status.value == null || x.status == status.value)
      .toList();

  // ---------------- Actions ----------------
  void onSearchChanged(String v) => query.value = v;
  void selectStatus(SaleStatus? s) => status.value = s;

  // ---------------- Navigation ----------------
  void onSaleTap(Sale s) =>
      Get.toNamed(AppRoutes.transactionDetail, arguments: s.invoice);
  void onBackPressed() => Get.back();
  void onNavTap(int index) => OwnerNav.goToTab(index);
}
