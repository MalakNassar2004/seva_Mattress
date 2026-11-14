import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'po_mock.dart';
import 'po_models.dart';
import 'purchase_orders_controller.dart';

/// Purchase Orders list (owner) with tabs Draft | Ordered | Partially
/// Received | Received. Shows the owner navigation with More selected.
class PurchaseOrdersView extends GetView<PurchaseOrdersController> {
  const PurchaseOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Obx(() {
                  // Rebuild when POs change (receipts, new drafts).
                  controller.store.orders.length;
                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(0, 12.h, 0, 16.h),
                    children: [
                      _pad(_buildHeader()),
                      SizedBox(height: 14.h),
                      _pad(_buildSummary()),
                      SizedBox(height: 14.h),
                      _pad(_buildSearch()),
                      SizedBox(height: 12.h),
                      _buildTabs(),
                      SizedBox(height: 14.h),
                      ..._buildList(),
                      SizedBox(height: 4.h),
                      Center(
                        child: StatusPill(
                          text: 'PCI-DSS Encrypted Ledger · CAD Verified',
                          icon: Icons.shield,
                          fg: AppColors.textDark.withValues(alpha: 0.8),
                          bg: AppColorsExtra.chipGrey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: PrimaryArrowButton(
                  label: '+ Create Purchase Order',
                  leadingIcon: Icons.add_circle_outline,
                  onPressed: controller.onCreatePressed,
                ),
              ),
              OwnerBottomNav(
                currentIndex: OwnerShellController.moreTab,
                moreBadge: OwnerShellController.moreBadge,
                onTap: controller.onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pad(Widget child) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: child,
      );

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackPill(label: 'More', onTap: controller.onBackPressed),
            const Spacer(),
            const StatusPill(
              text: 'Surrey Flagship · Owner View',
              dot: true,
              fg: AppColors.deepBlue,
              bg: AppColorsExtra.infoBg,
              border: AppColorsExtra.infoBorder,
              fontSize: 11,
            ),
            const Spacer(),
            CircleIconButton(
              icon: Icons.sync,
              onTap: controller.onRefreshPressed,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'Purchase Orders',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: controller.onArchivePressed,
              child: Icon(Icons.archive_rounded,
                  size: 24.sp, color: AppColors.deepBlue),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Procurement Ledger & Receiving · CAD Currency',
          style: TextStyle(
            fontSize: 12.5.sp,
            color: AppColors.textDark.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  // ---------------- Summary ----------------
  Widget _buildSummary() {
    final hidden = controller.valueHidden.value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Open PO Value',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark.withValues(alpha: 0.75),
                ),
              ),
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: controller.toggleValueHidden,
                child: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 17.sp,
                  color: AppColors.grey,
                ),
              ),
              const Spacer(),
              const StatusPill(
                text: PurchaseOrdersController.openValueTrend,
                icon: Icons.trending_up,
                fg: AppColors.success,
                bg: AppColorsExtra.successSoft,
                border: AppColorsExtra.successBorder,
                fontSize: 11,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hidden ? '\$ ••••••' : formatCad(controller.openValue),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 5.h),
                child: Text(
                  'CAD',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 12.h),
          Row(
            children: [
              _kpi('${controller.activeCount}', 'Active POs', AppColors.textDark),
              SizedBox(width: 8.w),
              _kpi('${controller.awaitingCount}', 'Awaiting Del.',
                  AppColors.primaryBlue),
              SizedBox(width: 8.w),
              _kpi('${controller.partialCount}', 'Partial Ship',
                  AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColorsExtra.panelGrey,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsExtra.panelBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Search & tabs ----------------
  Widget _buildSearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.small,
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 22.sp, color: AppColors.grey),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearchChanged,
                    style:
                        TextStyle(fontSize: 14.sp, color: AppColors.textDark),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search PO#, vendor, SKU...',
                      hintStyle: TextStyle(
                          fontSize: 13.sp, color: AppColors.greyLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10.w),
        GestureDetector(
          onTap: controller.onScanPressed,
          child: Container(
            width: 48.h,
            height: 48.h,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.small,
            ),
            child: Icon(Icons.qr_code_scanner,
                size: 22.sp, color: AppColors.primaryBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final sel = controller.tabIndex.value;
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: PurchaseOrdersController.tabs.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final s = PurchaseOrdersController.tabs[i];
          final active = i == sel;
          return GestureDetector(
            onTap: () => controller.selectTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primaryBlue : AppColors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: active ? AppColors.primaryBlue : AppColors.border,
                ),
              ),
              child: Text(
                '${s?.label ?? 'All'} (${controller.countFor(s)})',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.white : AppColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- List ----------------
  List<Widget> _buildList() {
    final list = controller.visible;
    if (list.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 36.h),
          child: Column(
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long_outlined,
                    size: 28.sp, color: AppColors.primaryBlue),
              ),
              SizedBox(height: 12.h),
              Text(
                'No purchase orders here',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return list
        .map((o) => Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: _PoCard(
                order: o,
                supplierName: controller.supplierOf(o)?.name ?? 'Unknown supplier',
                supplierSub: _supplierSub(o),
                onTap: () => controller.onCardTap(o),
                onReceive: () => controller.onReceivePressed(o),
                onFreight: () => controller.onViewFreightPressed(o),
                onResume: () => controller.onResumePressed(o),
              ),
            ))
        .toList();
  }

  String _supplierSub(PurchaseOrder o) {
    final s = controller.supplierOf(o);
    if (s == null) return '';
    final tag = s.preferred ? 'Regional Supplier' : s.category.split(' ').first;
    return '${s.city} · $tag';
  }
}

class _PoCard extends StatelessWidget {
  const _PoCard({
    required this.order,
    required this.supplierName,
    required this.supplierSub,
    required this.onTap,
    required this.onReceive,
    required this.onFreight,
    required this.onResume,
  });

  final PurchaseOrder order;
  final String supplierName;
  final String supplierSub;
  final VoidCallback onTap;
  final VoidCallback onReceive;
  final VoidCallback onFreight;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final o = order;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        o.number,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      StatusPill(
                        text: o.status.label,
                        fg: o.status.fg,
                        bg: o.status.bg,
                        border: o.status.border,
                        fontSize: 10.5,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCad(o.total),
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'CAD',
                      style:
                          TextStyle(fontSize: 10.5.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              supplierName,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              supplierSub,
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
            ),
            SizedBox(height: 10.h),
            _itemsPanel(),
            SizedBox(height: 12.h),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _itemsPanel() {
    final o = order;
    final (IconData, String, Color) tag = switch (o.status) {
      PoStatus.partial || PoStatus.ordered when o.overdue => (
          Icons.schedule,
          'Overdue',
          AppColors.danger
        ),
      PoStatus.ordered => (
          Icons.local_shipping_outlined,
          o.freight ?? 'Confirmed',
          AppColors.primaryBlue
        ),
      PoStatus.partial => (
          Icons.inventory_outlined,
          '${o.remainingUnits} left',
          AppColorsExtra.amberText
        ),
      PoStatus.draft => (Icons.edit_note, 'Unsubmitted', AppColors.grey),
      PoStatus.received => (
          Icons.check_circle_outline,
          'Complete',
          AppColors.success
        ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined, size: 16.sp, color: AppColors.deepBlue),
          SizedBox(width: 6.w),
          Text(
            '${o.itemCount} item${o.itemCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Expanded(
            child: Text(
              ' · ${o.itemSummary}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textDark.withValues(alpha: 0.75),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Icon(tag.$1, size: 13.sp, color: tag.$3),
          SizedBox(width: 3.w),
          Text(
            tag.$2,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: tag.$3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final o = order;
    switch (o.status) {
      case PoStatus.draft:
        return Row(
          children: [
            Icon(Icons.schedule, size: 15.sp, color: AppColors.grey),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                'Last edited ${o.lastEdited ?? 'recently'}',
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
            ),
            _smallButton('Resume PO', Icons.edit, onResume),
          ],
        );
      case PoStatus.received:
        return Row(
          children: [
            Icon(Icons.inventory_outlined, size: 15.sp, color: AppColors.success),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                'Received ${o.receivedOn ?? formatPoDate(o.expected)}',
                style: TextStyle(fontSize: 12.sp, color: AppColors.success),
              ),
            ),
            if (o.invoice != null)
              Text(
                'Invoice ${o.invoice}',
                style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
              ),
          ],
        );
      case PoStatus.ordered:
      case PoStatus.partial:
        final overdue = o.overdue;
        final days = o.expected.difference(PoMock.today).inDays;
        final when = days == -1
            ? 'Yesterday (${formatPoShortDate(o.expected)})'
            : formatPoDate(o.expected);
        return Row(
          children: [
            Icon(
              overdue ? Icons.warning_amber_rounded : Icons.event_available,
              size: 16.sp,
              color: overdue ? AppColorsExtra.amberText : AppColors.primaryBlue,
            ),
            SizedBox(width: 5.w),
            Expanded(
              child: Text(
                'Expected $when',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: overdue ? FontWeight.w600 : FontWeight.w500,
                  color: overdue ? AppColorsExtra.amberText : AppColors.textDark,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            if (o.status == PoStatus.partial || overdue)
              Material(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(22.r),
                child: InkWell(
                  onTap: onReceive,
                  borderRadius: BorderRadius.circular(22.r),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    child: Row(
                      children: [
                        Text(
                          'Receive Goods',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward,
                            size: 16.sp, color: AppColors.primaryBlue),
                      ],
                    ),
                  ),
                ),
              )
            else
              _smallButton('View Freight', Icons.north_east, onFreight),
          ],
        );
    }
  }

  Widget _smallButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColorsExtra.panelGrey,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(icon, size: 13.sp, color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}
