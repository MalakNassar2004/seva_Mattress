import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/dates.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../sales/sales_models.dart';
import 'transaction_detail_controller.dart';
import 'transaction_widgets.dart';

/// Transaction detail (one invoice).
class TransactionDetailView extends GetView<TransactionDetailController> {
  const TransactionDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Obx(() {
            controller.store.sales.length;
            final s = controller.sale;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    children: [
                      _buildHeader(s),
                      if (s.refundState == RefundState.pending) ...[
                        SizedBox(height: 12.h),
                        _buildPendingRefund(s),
                      ],
                      SizedBox(height: 14.h),
                      _buildLines(s),
                      SizedBox(height: 12.h),
                      _buildTotals(s),
                      SizedBox(height: 12.h),
                      _buildPayments(s),
                      SizedBox(height: 12.h),
                      _buildTimeline(s),
                      SizedBox(height: 14.h),
                      const AuditNote(
                        'Refunds and voids are recorded in the audit log',
                      ),
                    ],
                  ),
                ),
                _buildActions(),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader(Sale s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackPill(label: 'Transactions', onTap: controller.onBackPressed),
            SizedBox(width: 8.w),
            const Spacer(),
            const StatusPill(
              text: 'OWNER',
              fg: AppColors.deepBlue,
              bg: AppColors.lightBlue,
              fontSize: 10.5,
              letterSpacing: 0.5,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        PageTitle(
          title: 'Invoice #${s.invoice}',
          subtitle: '${s.customer} · ${formatWhen(s.time)}',
          badge: SaleStatusChip(s.status),
        ),
      ],
    );
  }

  Widget _buildPendingRefund(Sale s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.warningSoft,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsExtra.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: StatusPill(
                  text: 'Pending confirmation',
                  icon: Icons.hourglass_top,
                  fg: AppColorsExtra.amberText,
                  bg: AppColorsExtra.amberSoft,
                  border: AppColorsExtra.amberBorder,
                  fontSize: 11,
                ),
              ),
              SizedBox(width: 8.w),
              const Spacer(),
              Text(
                '-${formatCad(s.refunded)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Marked complete only after the payment provider confirms.',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.35,
              color: AppColorsExtra.amber,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Line items ----------------
  Widget _buildLines(Sale s) {
    final showCost = controller.costVisible.value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: Icons.shopping_bag_outlined,
            title: 'Line items',
            trailing: GestureDetector(
              onTap: controller.toggleCost,
              child: Row(
                children: [
                  Text(
                    'Cost',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    showCost
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18.sp,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          ),
          for (final l in s.lines) ...[
            SizedBox(height: 12.h),
            const Divider(color: AppColorsExtra.panelBorder),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBox(l.type.icon, size: 36),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${l.size} · ${l.qty} × ${formatCad(l.price)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.grey,
                        ),
                      ),
                      if (showCost) ...[
                        SizedBox(height: 6.h),
                        StatusPill(
                          text:
                              'Cost ${formatCad(l.costTotal)} · '
                              'Margin ${l.marginPct.toStringAsFixed(1)}%',
                          icon: Icons.lock_outline,
                          fg: AppColors.deepBlue,
                          bg: AppColorsExtra.infoBg,
                          border: AppColorsExtra.infoBorder,
                          fontSize: 10.5,
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  formatCad(l.total),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- Totals ----------------
  Widget _amountRow(
    String label,
    String value, {
    bool strong = false,
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: strong ? 15.sp : 13.5.sp,
                fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
                color: color ?? AppColors.textDark.withValues(alpha: 0.85),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 18.sp : 13.5.sp,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              color:
                  color ?? (strong ? AppColors.deepBlue : AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(Sale s) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.calculate_outlined, title: 'Totals'),
          SizedBox(height: 10.h),
          _amountRow('Subtotal', formatCad(s.subtotal)),
          _amountRow(
            'Discount',
            s.discount == 0 ? formatCad(0) : '-${formatCad(s.discount)}',
          ),
          _amountRow('GST (5%)', formatCad(s.gst)),
          _amountRow('PST (7%)', formatCad(s.pst)),
          SizedBox(height: 6.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 6.h),
          _amountRow('Total', formatCad(s.total), strong: true),
          if (s.refunded > 0)
            _amountRow(
              'Refunded',
              '-${formatCad(s.refunded)}',
              color: AppColors.danger,
            ),
        ],
      ),
    );
  }

  // ---------------- Payments ----------------
  Widget _buildPayments(Sale s) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.credit_card, title: 'Payments'),
          if (s.payments.isEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              'No payments recorded.',
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
            ),
          ],
          for (final p in s.payments) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                IconBox(p.method.icon, size: 36),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Ref ${p.reference}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontFamily: 'monospace',
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCad(p.amount),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 12.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 6.h),
          _amountRow(
            'Balance owing',
            formatCad(s.status == SaleStatus.voided ? 0 : s.balance),
            color: s.balance > 0 && s.status != SaleStatus.voided
                ? AppColorsExtra.amberText
                : null,
          ),
        ],
      ),
    );
  }

  // ---------------- Timeline ----------------
  Widget _buildTimeline(Sale s) {
    final events = s.timeline;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.timeline, title: 'Timeline'),
          SizedBox(height: 8.h),
          for (var i = 0; i < events.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: const BoxDecoration(
                          color: AppColors.lightBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          events[i].icon,
                          size: 14.sp,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      if (i < events.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColorsExtra.panelBorder,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 4.h, bottom: 14.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            events[i].label,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${events[i].by} · ${formatWhen(events[i].time)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Actions ----------------
  Widget _buildActions() {
    final canRefund = controller.canRefund;
    final canVoid = controller.canVoid;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  label: 'Print receipt',
                  icon: Icons.print_outlined,
                  height: 46,
                  onTap: controller.onPrint,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SoftButton(
                  label: 'Email receipt',
                  icon: Icons.mail_outline,
                  height: 46,
                  onTap: controller.onEmail,
                ),
              ),
            ],
          ),
          if (canRefund || canVoid) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                if (canRefund)
                  Expanded(
                    child: SoftButton(
                      label: 'Refund',
                      icon: Icons.undo,
                      height: 46,
                      fg: AppColors.danger,
                      borderColor: AppColors.danger,
                      onTap: controller.onRefund,
                    ),
                  ),
                if (canVoid)
                  TextButton(
                    onPressed: controller.onVoid,
                    child: Text(
                      'Void',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
