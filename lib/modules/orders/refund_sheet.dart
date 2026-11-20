import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/repositories/refund_repository.dart';
import 'package:seva_mattress/data/services/payment_methods.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

/// A product line of the order that can be returned.
class RefundLine {
  const RefundLine({
    required this.productId,
    required this.name,
    required this.details,
    required this.qty,
    required this.maxQty,
    required this.unitCents,
    required this.trackStock,
  });

  final String productId;
  final String name;
  final String details;

  /// Units bought.
  final int qty;

  /// Units that can still be returned (bought minus already returned).
  final int maxQty;
  final int unitCents;

  /// true = the units can go back to the stock.
  final bool trackStock;
}

/// What the owner chose in the Refund sheet.
class RefundInput {
  const RefundInput({
    required this.amountCents,
    required this.method,
    required this.reason,
    required this.items,
  });

  final int amountCents;
  final String method;
  final String reason;
  final List<Map<String, dynamic>> items;
}

class RefundController extends GetxController {
  RefundController({
    required this.number,
    required this.lines,
    required this.gstBp,
    required this.pstBp,
    required this.refundableCents,
    required this.subtotalCents,
    required this.discountCents,
    required this.canReturnItems,
  });

  final String number;
  final List<RefundLine> lines;
  final int gstBp;
  final int pstBp;

  /// The most that can be refunded (paid minus already refunded).
  final int refundableCents;

  /// The items of the order and the discount given on it (for the share of
  /// the discount that belongs to the returned items).
  final int subtotalCents;
  final int discountCents;

  /// false for a cancelled order: its items are already back in stock.
  final bool canReturnItems;

  /// The methods the owner turned on in Settings > Payment methods.
  List<String> get methods => PaymentMethodsConfig.enabled;

  // Not disposed on purpose: the closing animation of the sheet is still
  // drawing these fields (disposing them then crashes the screen).
  final amountController = TextEditingController();
  final reasonController = TextEditingController();

  late final qtys = List<int>.filled(lines.length, 0).obs;
  late final damaged = List<bool>.filled(lines.length, false).obs;
  final methodIndex = 0.obs;
  final amountCents = 0.obs;
  final error = RxnString();

  int get _itemsCents {
    var sum = 0;
    for (var i = 0; i < lines.length; i++) {
      sum += lines[i].unitCents * qtys[i];
    }
    return sum;
  }

  /// The returned items, minus their share of the discount, plus GST and PST
  /// (each rounded on its own), as the customer paid them.
  int get _itemsWithTax {
    final items = _itemsCents;
    final share = subtotalCents > 0
        ? (discountCents * items + subtotalCents ~/ 2) ~/ subtotalCents
        : 0;
    final taxable = items - share;
    final gst = (taxable * gstBp + 5000) ~/ 10000;
    final pst = (taxable * pstBp + 5000) ~/ 10000;
    return taxable + gst + pst;
  }

  void _setAmount(int cents) {
    final c = cents > refundableCents ? refundableCents : cents;
    amountCents.value = c;
    amountController.text = c <= 0 ? '' : (c / 100).toStringAsFixed(2);
  }

  void inc(int i) {
    if (qtys[i] >= lines[i].maxQty) return;
    qtys[i]++;
    _setAmount(_itemsWithTax);
    error.value = null;
  }

  void dec(int i) {
    if (qtys[i] <= 0) return;
    qtys[i]--;
    _setAmount(_itemsWithTax);
    error.value = null;
  }

  void setDamaged(int i, bool value) {
    damaged[i] = value;
    error.value = null;
  }

  void onAmountChanged(String v) {
    amountCents.value =
        ((double.tryParse(v.replaceAll(',', '')) ?? 0) * 100).round();
    error.value = null;
  }

  void selectMethod(int i) => methodIndex.value = i;

  void onConfirm() {
    final cents = amountCents.value;
    if (cents <= 0) {
      error.value = 'Enter an amount above \$0.00';
      return;
    }
    if (cents > refundableCents) {
      error.value = 'The most that can be refunded is '
          '${formatCad(refundableCents / 100)}';
      return;
    }
    final reason = reasonController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (reason.length < 3) {
      error.value = 'Write the reason for the refund';
      return;
    }
    final list = methods;
    Get.back(
      result: RefundInput(
        amountCents: cents,
        method: list[methodIndex.value.clamp(0, list.length - 1)],
        reason: reason,
        items: [
          for (var i = 0; i < lines.length; i++)
            if (qtys[i] > 0)
              {
                'productId': lines[i].productId,
                'name': lines[i].name,
                'qty': qtys[i],
                'unitCents': lines[i].unitCents,
                'damaged': damaged[i],
                'trackStock': lines[i].trackStock,
              },
        ],
      ),
    );
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Refund. Open the whole flow with RefundFlow.start().
class RefundSheet extends GetView<RefundController> {
  const RefundSheet({super.key});

  static Future<RefundInput?> open(RefundController c) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<RefundController>()) {
      Get.delete<RefundController>(force: true);
    }
    Get.put(c);
    return Get.bottomSheet<RefundInput>(
      const RefundSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  Widget _label(String t) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    ),
  );

  Widget _lineRow(int i) {
    final c = controller;
    final l = c.lines[i];
    return Obx(() {
      final q = c.qtys[i];
      final dmg = c.damaged[i];
      return Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.name,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${formatCad(l.unitCents / 100)} each · bought '
                        '${l.qty} · can return ${l.maxQty}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: q > 0 ? () => c.dec(i) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primaryBlue,
                ),
                SizedBox(
                  width: 22.w,
                  child: Text(
                    '$q',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: q < l.maxQty ? () => c.inc(i) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
            if (q > 0 && l.trackStock)
              Wrap(
                spacing: 8.w,
                children: [
                  ChoicePill(
                    label: 'Sellable (back to stock)',
                    selected: !dmg,
                    onTap: () => c.setDamaged(i, false),
                  ),
                  ChoicePill(
                    label: 'Damaged',
                    selected: dmg,
                    onTap: () => c.setDamaged(i, true),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SheetFrame(
      footer: Obx(
        () => PrimaryArrowButton(
          label: 'Refund ${formatCad(c.amountCents.value / 100)}',
          leadingIcon: Icons.undo,
          onPressed: c.onConfirm,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Refund',
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SheetCloseButton(onTap: c.onClosePressed),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Order ${c.number} · up to ${formatCad(c.refundableCents / 100)}',
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
          ),
          SizedBox(height: 16.h),
          if (c.canReturnItems) ...[
            _label('Items returned (optional)'),
            for (var i = 0; i < c.lines.length; i++) _lineRow(i),
            if (c.discountCents > 0)
              Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  'This order had a discount: returned items are refunded at '
                  'the price the customer paid.',
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                ),
              ),
          ] else
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                'This order was cancelled, so its items are already back in '
                'stock. Enter the amount to give back.',
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
            ),
          SizedBox(height: 6.h),
          LabeledInput(
            controller: c.amountController,
            label: 'Amount to refund (CAD, tax included)',
            hint: '0.00',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: c.onAmountChanged,
          ),
          SizedBox(height: 14.h),
          _label('Refund to'),
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(
                c.methods.length,
                (i) => ChoicePill(
                  label: c.methods[i],
                  selected: c.methodIndex.value == i,
                  onTap: () => c.selectMethod(i),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          LabeledInput(
            controller: c.reasonController,
            label: 'Reason',
            hint: 'e.g. Returned within the sleep trial',
            maxLines: 2,
            onChanged: (_) => c.error.value = null,
          ),
          Obx(() {
            final err = c.error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: Text(
                err,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            );
          }),
          SizedBox(height: 12.h),
          const AuditNote(
            'Every refund is recorded in the audit log',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}

/// The whole refund flow: who can refund, the sheet, then the save.
class RefundFlow {
  RefundFlow._();

  static void _toast(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }

  static Future<void> start({
    required String orderId,
    required Map<String, dynamic> order,
  }) async {
    if (orderId.isEmpty || order.isEmpty) return;

    var allowed = false;
    try {
      final user = await SessionService().loadCurrentUser();
      allowed = (user?.isOwner ?? false) || (user?.isManager ?? false);
    } catch (_) {
      allowed = false;
    }
    if (!allowed) {
      _toast('Not allowed', 'Only the owner or a manager can refund.');
      return;
    }

    int c(Object? v) => (v as num?)?.toInt() ?? 0;

    final refundable = c(order['paidCents']) - c(order['refundedCents']);
    if (refundable <= 0) {
      _toast(
        'Nothing to refund',
        'No money was paid on this order, or it was already refunded.',
      );
      return;
    }

    final taxBp = c(order['taxBp']);
    final gstBp = order['gstBp'] == null ? 500 : c(order['gstBp']);
    final pstBp = order['pstBp'] == null
        ? (taxBp > 500 ? taxBp - 500 : 0)
        : c(order['pstBp']);

    final stockTracked = order['stockTracked'] == true;
    final cancelled = order['status'] == 'cancelled';
    final returned = order['returnedUnits'] is Map
        ? Map<String, dynamic>.from(order['returnedUnits'] as Map)
        : <String, dynamic>{};

    final lines = <RefundLine>[
      for (final l in ((order['lines'] as List?) ?? const []))
        if (l is Map)
          () {
            final id = (l['productId'] as String?) ?? '';
            final qty = c(l['qty']);
            final back = c(returned[id]);
            return RefundLine(
              productId: id,
              name: (l['name'] as String?) ?? '',
              details: (l['details'] as String?) ?? '',
              qty: qty,
              maxQty: (qty - back).clamp(0, qty).toInt(),
              unitCents: c(l['unitCents']),
              trackStock: stockTracked && l['trackStock'] == true,
            );
          }(),
    ];

    final input = await RefundSheet.open(
      RefundController(
        number: (order['number'] as String?) ?? '',
        lines: lines,
        gstBp: gstBp,
        pstBp: pstBp,
        refundableCents: refundable,
        subtotalCents: c(order['subtotalCents']),
        discountCents: c(order['discountCents']),
        canReturnItems: !cancelled,
      ),
    );
    if (input == null) return;

    final repo = RefundRepository();
    try {
      await repo.refund(
        orderId: orderId,
        refundId: repo.newRefundId(orderId),
        amountCents: input.amountCents,
        method: input.method,
        reason: input.reason,
        items: input.items,
      );
      _toast(
        'Refund recorded',
        '${formatCad(input.amountCents / 100)} · ${input.method}',
      );
    } catch (e) {
      _toast('Could not refund', describeCustomerError(e));
    }
  }
}