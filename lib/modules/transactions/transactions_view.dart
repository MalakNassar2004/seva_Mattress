import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/dates.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import '../sales/sales_models.dart';
import 'transaction_widgets.dart';
import 'transactions_controller.dart';

/// Transactions list (owner). Opened from Reports.
class TransactionsView extends GetView<TransactionsController> {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  children: [
                    Row(
                      children: [
                        BackPill(
                          label: 'Reports',
                          onTap: controller.onBackPressed,
                        ),
                        SizedBox(width: 8.w),
                        const Spacer(),
                        const StatusPill(
                          text: 'CAD (\$)',
                          fg: AppColors.deepBlue,
                          bg: AppColors.lightBlue,
                          fontSize: 12,
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    const PageTitle(
                      title: 'Transactions',
                      subtitle: 'Surrey Showroom · Registers & online',
                    ),
                    SizedBox(height: 14.h),
                    AppSearchBar(
                      hint: 'Search invoice #, customer, SKU...',
                      onChanged: controller.onSearchChanged,
                    ),
                    SizedBox(height: 12.h),
                    Obx(_buildChips),
                    SizedBox(height: 14.h),
                    Obx(_buildList),
                    const AuditNote(
                      'PCI-DSS Level 1 Encrypted · Interac verified',
                    ),
                  ],
                ),
              ),
              OwnerBottomNav(
                currentIndex: OwnerShellController.reportsTab,
                moreBadge: OwnerShellController.moreBadge,
                onTap: controller.onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChips() {
    controller.store.sales.length;
    final options = <SaleStatus?>[null, ...SaleStatus.values];
    return FilterChipBar(
      options: [
        for (final s in options)
          FilterOption(s?.label ?? 'All', count: controller.countFor(s)),
      ],
      selectedIndex: options.indexOf(controller.status.value),
      onSelected: (i) => controller.selectStatus(options[i]),
    );
  }

  Widget _buildList() {
    controller.store.sales.length;
    final list = controller.visible;
    if (list.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'No transactions match',
      );
    }
    return Column(
      children: [
        for (final s in list)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _SaleCard(sale: s, onTap: () => controller.onSaleTap(s)),
          ),
      ],
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale, required this.onTap});

  final Sale sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = sale;
    final (fg, bg, _) = s.status.colors;
    final refunded = s.status == SaleStatus.refunded;
    final voided = s.status == SaleStatus.voided;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Invoice #${s.invoice}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                SaleStatusChip(s.status, fontSize: 10.5),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    formatWhen(s.time),
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            const Divider(color: AppColorsExtra.panelBorder),
            SizedBox(height: 10.h),
            Row(
              children: [
                InitialsAvatar(
                  initials: s.customerInitials,
                  size: 38,
                  bg: s.status == SaleStatus.paid ? AppColors.lightBlue : bg,
                  fg: s.status == SaleStatus.paid ? AppColors.deepBlue : fg,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.customer,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Cashier: ${s.cashier}'
                        '${s.note == null ? '' : ' · ${s.note}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: AppColors.textDark.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: AppColors.greyLight,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColorsExtra.panelBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    s.lines.first.type.icon,
                    size: 16.sp,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '${s.summary}\n'
                      '(${s.itemCount} item${s.itemCount == 1 ? '' : 's'})',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        height: 1.35,
                        color: AppColors.textDark.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (s.status == SaleStatus.deposit && s.balance > 0) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColorsExtra.amberSoft,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Deposit paid: ${formatCad(s.paid)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColorsExtra.amberText,
                        ),
                      ),
                    ),
                    Text(
                      'Balance: ${formatCad(s.balance)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColorsExtra.amberText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 10.h),
            Row(
              children: [
                InitialsAvatar(initials: s.cashierInitials, size: 26),
                SizedBox(width: 6.w),
                Flexible(
                  child: refunded
                      ? const StatusPill(
                          text: 'Refund',
                          icon: Icons.undo,
                          fg: AppColors.danger,
                          bg: AppColorsExtra.dangerSoft,
                          fontSize: 11,
                        )
                      : StatusPill(
                          text: voided
                              ? 'No payment'
                              : s.payments.isEmpty
                              ? 'Unpaid'
                              : s.payments.first.label,
                          icon: voided
                              ? Icons.block
                              : s.payments.isEmpty
                              ? Icons.schedule
                              : s.payments.first.method.icon,
                          fg: AppColors.textDark,
                          bg: AppColorsExtra.chipGrey,
                          fontSize: 11,
                        ),
                ),
                SizedBox(width: 8.w),
                const Spacer(),
                Text(
                  refunded ? '-${formatCad(s.refunded)}' : formatCad(s.total),
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: refunded
                        ? AppColors.danger
                        : voided
                        ? AppColors.greyLight
                        : AppColors.deepBlue,
                    decoration: voided ? TextDecoration.lineThrough : null,
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  'CAD',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
