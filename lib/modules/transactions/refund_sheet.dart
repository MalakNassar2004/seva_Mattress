import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../sales/sales_models.dart';

/// What the owner submitted in the refund sheet.
class RefundRequest {
  const RefundRequest({
    required this.full,
    required this.amount,
    required this.reason,
    required this.method,
    required this.note,
  });

  final bool full;
  final double amount;
  final String reason;
  final String method;
  final String note;
}

/// Bottom sheet: Issue refund (full or partial).
class RefundSheet extends StatefulWidget {
  const RefundSheet({super.key, required this.sale, required this.refundable});

  final Sale sale;

  /// Amount still refundable (tax included).
  final double refundable;

  static const reasons = [
    'Comfort guarantee (100-night trial)',
    'Damaged or defective',
    'Wrong size delivered',
    'Price adjustment',
    'Order cancelled',
    'Other',
  ];

  static Future<RefundRequest?> open(Sale sale, double refundable) =>
      Get.bottomSheet<RefundRequest>(
        RefundSheet(sale: sale, refundable: refundable),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
      );

  @override
  State<RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<RefundSheet> {
  bool _full = true;
  late final Set<int> _items = {
    for (var i = 0; i < widget.sale.lines.length; i++) i,
  };
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _reason = RefundSheet.reasons.first;
  late String _method = _methods.first;
  String? _error;

  Sale get _s => widget.sale;

  List<String> get _methods => [
    if (_s.payments.isNotEmpty) 'Original payment (${_s.payments.first.label})',
    'Store credit',
    'Cash',
  ];

  /// Line total with its share of the discount, plus tax.
  double _lineRefund(SaleLine l) {
    final k = _s.subtotal == 0 ? 0 : _s.taxable / _s.subtotal;
    return l.total * k * (1 + gstRate + pstRate);
  }

  double get _amountValue {
    if (_full) return widget.refundable;
    final typed = double.tryParse(_amount.text.replaceAll(',', ''));
    if (typed != null && typed > 0) return typed;
    return _items.fold<double>(0, (a, i) => a + _lineRefund(_s.lines[i]));
  }

  void _confirm() {
    final amount = _amountValue;
    if (amount <= 0) {
      setState(() => _error = 'Choose items or enter an amount');
      return;
    }
    if (amount > widget.refundable + 0.01) {
      setState(
        () => _error = 'Maximum refundable is ${formatCad(widget.refundable)}',
      );
      return;
    }
    Get.back(
      result: RefundRequest(
        full: _full || (amount - widget.refundable).abs() < 0.01,
        amount: amount,
        reason: _reason,
        method: _method,
        note: _note.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      heightFactor: 0.9,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DangerButton(
            caption: 'Execute action',
            label: 'Confirm refund (${formatCad(_amountValue)} CAD)',
            onTap: _confirm,
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              label: 'Cancel',
              height: 50,
              radius: 16,
              fontSize: 14.5,
              onTap: Get.back,
            ),
          ),
        ],
      ),
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
                      'Issue Refund',
                      style: TextStyle(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Invoice #${_s.invoice} · ${_s.customer}',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SheetCloseButton(onTap: Get.back),
            ],
          ),
          SizedBox(height: 14.h),
          const InfoBanner(
            icon: Icons.shield_outlined,
            child: Text(
              'This action is recorded in the audit log with your name and '
              'time.',
            ),
          ),
          SizedBox(height: 16.h),
          const Caption('Refund scope'),
          SizedBox(height: 8.h),
          SegmentedTabs(
            labels: [
              'Full refund\n(${formatCad(widget.refundable)})',
              'Partial refund',
            ],
            selectedIndex: _full ? 0 : 1,
            onChanged: (i) => setState(() {
              _full = i == 0;
              _error = null;
            }),
          ),
          if (!_full) ...[
            SizedBox(height: 16.h),
            const Caption('Items to return'),
            SizedBox(height: 8.h),
            for (var i = 0; i < _s.lines.length; i++) ...[
              _itemRow(i),
              SizedBox(height: 8.h),
            ],
            SizedBox(height: 4.h),
            LabeledInput(
              controller: _amount,
              label: 'Or enter an amount',
              hint: 'e.g. 250.00',
              prefixIcon: Icons.attach_money,
              suffixText: 'CAD',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
          ],
          if (_error != null) ...[
            SizedBox(height: 6.h),
            Text(
              _error!,
              style: TextStyle(fontSize: 12.sp, color: AppColors.danger),
            ),
          ],
          SizedBox(height: 16.h),
          const Caption('Return reason'),
          SizedBox(height: 8.h),
          _dropdown(
            value: _reason,
            items: RefundSheet.reasons,
            onSelected: (v) => setState(() => _reason = v),
          ),
          SizedBox(height: 16.h),
          const Caption('Refund method'),
          SizedBox(height: 8.h),
          for (final m in _methods) ...[
            SelectCard(
              icon: m.startsWith('Original')
                  ? Icons.credit_card
                  : m == 'Cash'
                  ? Icons.payments_outlined
                  : Icons.card_giftcard,
              title: m,
              subtitle: m.startsWith('Original')
                  ? 'Back to the card or account that paid'
                  : m == 'Cash'
                  ? 'Paid out from the register drawer'
                  : 'Credit saved on the customer profile',
              selected: m == _method,
              onTap: () => setState(() => _method = m),
            ),
            SizedBox(height: 8.h),
          ],
          SizedBox(height: 8.h),
          LabeledInput(
            controller: _note,
            label: 'Note',
            hint: 'Inspection notes, condition, pickup details...',
            maxLines: 3,
          ),
          SizedBox(height: 14.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.warningSoft,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColorsExtra.warningBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 17.sp,
                  color: AppColorsExtra.amber,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusPill(
                        text: 'PENDING CONFIRMATION',
                        fg: AppColorsExtra.amberText,
                        bg: AppColorsExtra.amberSoft,
                        border: AppColorsExtra.amberBorder,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Marked complete only after the payment provider '
                        'confirms.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.35,
                          color: AppColorsExtra.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _itemRow(int i) {
    final l = _s.lines[i];
    final on = _items.contains(i);
    return GestureDetector(
      onTap: () => setState(() {
        on ? _items.remove(i) : _items.add(i);
        _amount.clear();
        _error = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: on ? AppColorsExtra.infoBg : AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: on ? AppColorsExtra.infoBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              on ? Icons.check_box : Icons.check_box_outline_blank,
              size: 22.sp,
              color: on ? AppColors.primaryBlue : AppColors.greyLight,
            ),
            SizedBox(width: 10.w),
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
                    'Qty: ${l.qty} · ${l.size}',
                    style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            Text(
              formatCad(_lineRefund(l)),
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (_) => [
        for (final it in items)
          PopupMenuItem(
            value: it,
            child: Text(
              it,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: it == value ? FontWeight.w800 : FontWeight.w600,
                color: it == value ? AppColors.primaryBlue : AppColors.textDark,
              ),
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, size: 20.sp, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
