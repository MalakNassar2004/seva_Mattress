import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../purchase_orders/po_models.dart';
import 'cost_trend_chart.dart';
import 'supplier_detail_controller.dart';
import 'supplier_models.dart';

/// Supplier detail: contact, spend stats, cost trend, open POs & invoices,
/// purchase history and commercial terms.
class SupplierDetailView extends GetView<SupplierDetailController> {
  const SupplierDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Obx(() {
            // Rebuild when the store changes (edits, new POs, receipts).
            controller.store.orders.length;
            controller.store.suppliers.length;
            final s = controller.supplier;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: _buildTopBar(s),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                    children: [
                      _buildHero(s),
                      SizedBox(height: 12.h),
                      _buildContact(s),
                      SizedBox(height: 12.h),
                      _buildStats(s),
                      SizedBox(height: 12.h),
                      if (s.costTrend.isNotEmpty) ...[
                        _buildTrend(s),
                        SizedBox(height: 12.h),
                      ],
                      _buildOpenPos(),
                      SizedBox(height: 12.h),
                      _buildHistory(),
                      SizedBox(height: 12.h),
                      _buildTerms(s),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
                  child: Column(
                    children: [
                      PrimaryArrowButton(
                        label: '+ Create Purchase Order',
                        leadingIcon: Icons.add_circle_outline,
                        onPressed: controller.onCreatePoPressed,
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        child: SoftButton(
                          label: 'Manage Invoices & Terms',
                          icon: Icons.receipt_long_outlined,
                          height: 46,
                          fontSize: 13.5,
                          onTap: controller.onEditPressed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------- Top bar ----------------
  Widget _buildTopBar(Supplier s) {
    return Row(
      children: [
        BackPill(label: 'Suppliers', onTap: controller.onBackPressed),
        SizedBox(width: 8.w),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusPill(
              text: s.preferred ? 'Active Vendor · Preferred' : 'Active Vendor',
              dot: true,
              fg: AppColors.success,
              bg: AppColorsExtra.successSoft,
              border: AppColorsExtra.successBorder,
              fontSize: 11,
              maxLines: 2,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        SoftButton(
          label: 'Edit',
          height: 34,
          radius: 18,
          fontSize: 12.5,
          onTap: controller.onEditPressed,
        ),
        SizedBox(width: 8.w),
        CircleIconButton(icon: Icons.more_horiz, onTap: controller.onMorePressed),
      ],
    );
  }

  // ---------------- Hero ----------------
  Widget _buildHero(Supplier s) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (s.specialty.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.factory_outlined,
                              size: 14.sp, color: AppColors.deepBlue),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Caption(s.specialty,
                                color: AppColors.deepBlue),
                          ),
                        ],
                      ),
                    SizedBox(height: 4.h),
                    Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 21.sp,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColorsExtra.infoBorder),
                ),
                child: Icon(Icons.layers_outlined,
                    size: 22.sp, color: AppColors.deepBlue),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '${s.address} · Vendor #${s.id} · Lead Time: ${s.leadDays}',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.5,
              color: AppColors.textDark.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(height: 10.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 14.sp, color: AppColors.deepBlue),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  s.preferred ? 'Surrey Store Preferred Tier 1' : 'Standard Vendor',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                'Owner Store: Surrey, BC',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Contact ----------------
  Widget _buildContact(Supplier s) {
    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(initials: s.initials, size: 34),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.contact,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      s.contactRole,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const StatusPill(
                text: 'Available',
                dot: true,
                fg: AppColors.success,
                bg: AppColorsExtra.successSoft,
                fontSize: 10.5,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _contactButton(
                  Icons.call_outlined,
                  'Call ${s.phone.split(' ').first}',
                  controller.onCallPressed,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _contactButton(
                  Icons.mail_outline,
                  'Email Desk',
                  controller.onEmailPressed,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _contactButton(
                  Icons.menu_book_outlined,
                  'Catalog',
                  controller.onCatalogPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppColorsExtra.panelGrey,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          height: 42.h,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.sp, color: AppColors.primaryBlue),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Stats ----------------
  Widget _buildStats(Supplier s) {
    final outstanding = controller.outstanding;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _statTile(
              caption: 'Total spent',
              captionIcon: Icon(Icons.visibility_outlined,
                  size: 13.sp, color: AppColors.grey),
              value: formatCad(s.totalPurchased, decimals: 0),
              foot: Text(
                'CAD YTD',
                style: TextStyle(fontSize: 10.5.sp, color: AppColors.grey),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _statTile(
              caption: 'Outstanding',
              captionIcon: Container(
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(
                  color: outstanding > 0 ? AppColors.warning : AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              value: formatCad(outstanding, decimals: 0),
              valueColor: outstanding > 0
                  ? AppColorsExtra.amberText
                  : AppColors.success,
              foot: outstanding > 0 && controller.outstandingDue != null
                  ? StatusPill(
                      text: controller.outstandingDue!,
                      fg: AppColorsExtra.amberText,
                      bg: AppColorsExtra.amberSoft,
                      fontSize: 9.5,
                    )
                  : Text(
                      'All paid',
                      style:
                          TextStyle(fontSize: 10.5.sp, color: AppColors.success),
                    ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _statTile(
              caption: 'Lifetime',
              captionIcon: Icon(Icons.verified_outlined,
                  size: 13.sp, color: AppColors.success),
              value: '${s.lifetimePos} POs',
              foot: Text(
                '${s.fulfilledPct}% Fulfilled',
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String caption,
    required Widget captionIcon,
    required String value,
    required Widget foot,
    Color valueColor = AppColors.textDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Caption(caption),
                ),
              ),
              SizedBox(width: 4.w),
              captionIcon,
            ],
          ),
          SizedBox(height: 10.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          foot,
        ],
      ),
    );
  }

  // ---------------- Cost trend ----------------
  Widget _buildTrend(Supplier s) {
    final pct = controller.trendPct;
    final stable = pct.abs() < 3;
    final sign = pct > 0 ? '+' : '';
    final pctText = '$sign${pct.toStringAsFixed(1)}%';
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.costLabel} (Last 6 Months)',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Average \$${controller.averageCost.toStringAsFixed(2)} / ${s.costUnit}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textDark.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6.w),
              StatusPill(
                text: stable ? 'Stable ($pctText)' : (pct > 0 ? 'Rising ($pctText)' : 'Falling ($pctText)'),
                icon: stable ? null : (pct > 0 ? Icons.trending_up : Icons.trending_down),
                fg: stable || pct < 0 ? AppColors.success : AppColors.danger,
                bg: stable || pct < 0
                    ? AppColorsExtra.successSoft
                    : AppColorsExtra.dangerSoft,
                border: stable || pct < 0
                    ? AppColorsExtra.successBorder
                    : AppColorsExtra.dangerBorder,
                fontSize: 10.5,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          CostTrendChart(
            points: s.costTrend,
            selected: controller.selectedBar.value,
            onSelect: controller.selectBar,
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  stable
                      ? 'Forecasted CAD stability for Q4 inventory'
                      : 'Review pricing before the next PO',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Text(
                'Tap a month for its cost',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Open POs & invoices ----------------
  Widget _buildOpenPos() {
    final list = controller.openOrders;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Open POs & Outstanding Invoices',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                width: 20.w,
                height: 20.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.deepBlue,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${list.length}',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: controller.onViewAllPressed,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (list.isEmpty)
            Text(
              'No open purchase orders',
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
            )
          else
            ...list.map(_openPoRow),
        ],
      ),
    );
  }

  Widget _openPoRow(PurchaseOrder o) {
    final invoiced = o.invoice != null;
    final shipped = o.status == PoStatus.partial || o.freight == 'In Transit';
    return GestureDetector(
      onTap: () => controller.onOrderTap(o),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColorsExtra.panelGrey,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColorsExtra.panelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PO ${o.number}',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepBlue,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        o.lines.first.title,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCad(o.total),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: invoiced
                            ? AppColors.textDark
                            : AppColorsExtra.amberText,
                      ),
                    ),
                    Text(
                      'CAD',
                      style:
                          TextStyle(fontSize: 10.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                StatusPill(
                  text: shipped
                      ? (o.status == PoStatus.partial
                          ? 'Partially Received'
                          : 'Shipped · Est. ${formatPoShortDate(o.expected)}')
                      : (o.freight ?? 'Ordered'),
                  icon: shipped
                      ? Icons.local_shipping_outlined
                      : Icons.precision_manufacturing_outlined,
                  fg: shipped ? AppColors.success : AppColorsExtra.amberText,
                  bg: shipped ? AppColorsExtra.successSoft : AppColorsExtra.amberSoft,
                  fontSize: 10.5,
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    invoiced
                        ? '${controller.supplier.terms} · Invoice ${o.invoice}'
                        : '${controller.supplier.terms} · Pending Delivery',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textDark.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Purchase history ----------------
  Widget _buildHistory() {
    final list = controller.history;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.history, title: 'Purchase History'),
          SizedBox(height: 12.h),
          if (list.isEmpty)
            Text(
              'Nothing received from this supplier yet',
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
            )
          else
            ...List.generate(list.length, (i) {
              final o = list[i];
              return Column(
                children: [
                  if (i > 0) ...[
                    SizedBox(height: 10.h),
                    const Divider(color: AppColorsExtra.panelBorder),
                    SizedBox(height: 10.h),
                  ],
                  Row(
                    children: [
                      Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          color: AppColorsExtra.successSoft,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.inventory_outlined,
                            size: 17.sp, color: AppColors.success),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o.lines.map((l) => l.title).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${o.number} · Received ${o.receivedOn ?? formatPoDate(o.expected)}',
                              style: TextStyle(
                                  fontSize: 11.sp, color: AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCad(o.total),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ---------------- Terms ----------------
  Widget _buildTerms(Supplier s) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.assignment_outlined,
            title: 'Commercial Terms & Logistics',
          ),
          SizedBox(height: 12.h),
          _termRow('Payment Terms:', '${s.terms} Days (E-Transfer / Corporate EFT)'
              .replaceFirst('COD Days', 'Cash on Delivery')),
          _termRow('Delivery Mode:', s.deliveryMode),
          if (s.taxId.isNotEmpty) _termRow('Tax ID / Business No:', s.taxId),
          _termRow('Contact Email:', s.email),
          if (s.notes.isNotEmpty) ...[
            Text(
              'Production Notes:',
              style: TextStyle(
                fontSize: 12.5.sp,
                color: AppColors.textDark.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColorsExtra.panelBorder),
              ),
              child: Text(
                '"${s.notes}"',
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.45,
                  color: AppColors.textDark.withValues(alpha: 0.85),
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColorsExtra.panelBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16.sp, color: AppColors.grey),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'All vendor POs & bank transfers recorded in the audit log.',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                  ),
                ),
                Text(
                  'PCI-DSS L1',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _termRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: AppColors.textDark.withValues(alpha: 0.8),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
