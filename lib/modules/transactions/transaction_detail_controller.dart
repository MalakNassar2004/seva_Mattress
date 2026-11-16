import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../audit/audit_models.dart';
import '../audit/audit_store.dart';
import '../sales/sales_models.dart';
import '../sales/sales_store.dart';
import 'refund_sheet.dart';

/// Transaction detail. Arguments: invoice number (String).
/// UI state only. Backend wiring is marked with TODO(backend).
class TransactionDetailController extends GetxController {
  final store = SalesStore.to;
  late final String invoice = Get.arguments as String;

  /// Owner-only cost & margin, hidden until the eye is tapped.
  final costVisible = false.obs;

  Sale get sale => store.byInvoice(invoice)!;

  double get refundable => (sale.total - sale.refunded).clamp(0, sale.total);

  bool get canRefund =>
      sale.status != SaleStatus.voided &&
      refundable > 0.01 &&
      sale.paid > 0 &&
      sale.refundState != RefundState.pending;

  bool get canVoid => sale.status != SaleStatus.voided && sale.refunded == 0;

  // ---------------- Actions ----------------
  void toggleCost() => costVisible.toggle();

  void onPrint() {
    // TODO(backend): send the receipt to the thermal printer.
    showDarkToast('Receipt sent to the printer');
  }

  void onEmail() {
    // TODO(backend): email the receipt to the customer.
    showDarkToast('Receipt emailed to ${sale.customer}');
  }

  Future<void> onRefund() async {
    if (!canRefund) return;
    final r = await RefundSheet.open(sale, refundable);
    if (r == null) return;
    store.refund(sale, amount: r.amount, full: r.full);
    AuditStore.to.record(
      action: AuditAction.refund,
      sentence:
          '${r.full ? 'Full' : 'Partial'} refund on invoice '
          '#${sale.invoice}',
      oldValue: formatCad(r.amount),
      newValue: r.method,
      context: 'Owner Mobile · Reason: ${r.reason}',
    );
    showDarkToast('Refund submitted · Pending confirmation');
  }

  Future<void> onVoid() async {
    if (!canVoid) return;
    final ok = await showConfirmSheet(
      title: 'Void invoice #${sale.invoice}?',
      message:
          'The sale is cancelled and removed from sales totals. '
          'Payments already taken must be refunded separately.',
      confirmLabel: 'Void invoice',
      icon: Icons.block,
      danger: true,
    );
    if (!ok) return;
    store.voidSale(sale);
    AuditStore.to.record(
      action: AuditAction.refund,
      sentence: 'Voided invoice #${sale.invoice}',
      newValue: formatCad(sale.total),
    );
    showDarkToast('Invoice #${sale.invoice} voided');
  }

  void onBackPressed() => Get.back();
}
