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
import 'supplier_models.dart';
import 'suppliers_controller.dart';

/// Suppliers list (owner). Opened from the More tab, so it shows the owner
/// bottom navigation with More selected.
class SuppliersView extends GetView<SuppliersController> {
  const SuppliersView({super.key});

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
                    _buildHeader(),
                    SizedBox(height: 14.h),
                    Obx(_buildStats),
                    SizedBox(height: 14.h),
                    _buildSearch(),
                    SizedBox(height: 12.h),
                    Obx(_buildFilters),
                    SizedBox(height: 14.h),
                    Obx(_buildList),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: PrimaryArrowButton(
                  label: '+  Add Supplier',
                  onPressed: controller.onAddPressed,
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

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackPill(label: 'More', onTap: controller.onBackPressed),
            const Spacer(),
            Obx(
              () => StatusPill(
                text: 'Surrey Flagship · ${controller.store.suppliers.length} Active',
                dot: true,
                fg: AppColors.success,
                bg: AppColors.white,
                border: AppColors.border,
                fontSize: 11,
              ),
            ),
            SizedBox(width: 6.w),
            const StatusPill(
              text: 'PCI L1',
              icon: Icons.shield,
              fg: AppColors.deepBlue,
              bg: AppColors.white,
              border: AppColors.border,
              fontSize: 11,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'Suppliers',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const StatusPill(
              text: 'OWNER LEDGER',
              fg: AppColors.deepBlue,
              bg: AppColorsExtra.infoBg,
              border: AppColorsExtra.infoBorder,
              fontSize: 10.5,
              letterSpacing: 0.6,
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          'Vendor Directory & Purchase Ledger · CAD Currency',
          style: TextStyle(
            fontSize: 12.5.sp,
            color: AppColors.textDark.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  // ---------------- Stats ----------------
  Widget _buildStats() {
    final hidden = controller.spendHidden.value;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: _statBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Caption('Total spend YTD')),
                      GestureDetector(
                        onTap: controller.toggleSpendHidden,
                        child: Icon(
                          hidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18.sp,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hidden
                          ? '\$ •••••••'
                          : formatCad(SuppliersController.totalSpendYtd),
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      const StatusPill(
                        text: 'CAD',
                        fg: AppColors.deepBlue,
                        bg: AppColors.lightBlue,
                        fontSize: 10,
                      ),
                      SizedBox(width: 6.w),
                      Icon(Icons.trending_up,
                          size: 14.sp, color: AppColors.success),
                      SizedBox(width: 2.w),
                      Text(
                        SuppliersController.spendTrend,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 9,
            child: Column(
              children: [
                GestureDetector(
                  onTap: controller.onOpenPosPressed,
                  child: _miniStat(
                    'Open POs',
                    '${controller.openPoCount} Orders',
                    trailing: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                _miniStat(
                  'Avg Lead Time',
                  SuppliersController.avgLeadTime,
                  trailing: Icon(Icons.timer_outlined,
                      size: 16.sp, color: AppColors.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: child,
    );
  }

  Widget _miniStat(String label, String value, {required Widget trailing}) {
    return _statBox(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textDark.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Search & filters ----------------
  Widget _buildSearch() {
    return Container(
      height: 50.h,
      padding: EdgeInsets.only(left: 14.w, right: 8.w),
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
              onChanged: controller.onSearchChanged,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search supplier, rep, materials...',
                hintStyle:
                    TextStyle(fontSize: 13.sp, color: AppColors.greyLight),
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.onFiltersPressed,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.tune, size: 18.sp, color: AppColors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final sel = controller.filter.value;
    // Touch the list so counts refresh when suppliers or POs change.
    controller.store.orders.length;
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SupplierFilter.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final f = SupplierFilter.values[i];
          final active = f == sel;
          final count = controller.countFor(f);
          return GestureDetector(
            onTap: () => controller.selectFilter(f),
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
              child: Row(
                children: [
                  if (f == SupplierFilter.openPos) ...[
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                  ],
                  Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.white : AppColors.textDark,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  active
                      ? Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        )
                      : Text(
                          '($count)',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- List ----------------
  Widget _buildList() {
    // Touch the orders so open PO chips refresh.
    controller.store.orders.length;
    final list = controller.visible;
    if (list.isEmpty) {
      return Padding(
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
              child: Icon(Icons.local_shipping_outlined,
                  size: 28.sp, color: AppColors.primaryBlue),
            ),
            SizedBox(height: 12.h),
            Text(
              'No suppliers match',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: list
          .map((s) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _SupplierCard(
                  supplier: s,
                  openPos: controller.openPosOf(s),
                  openValue: controller.openValueOf(s),
                  onTap: () => controller.onSupplierTap(s),
                ),
              ))
          .toList(),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.openPos,
    required this.openValue,
    required this.onTap,
  });

  final Supplier supplier;
  final int openPos;
  final double openValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = supplier;
    final Widget secondChip;
    if (s.preferred) {
      secondChip = const StatusPill(
        text: 'Preferred Partner',
        icon: Icons.star,
        fg: AppColors.success,
        bg: AppColorsExtra.successSoft,
        border: AppColorsExtra.successBorder,
        fontSize: 11,
      );
    } else if (openPos > 0) {
      secondChip = StatusPill(
        text: 'Lead: ${s.leadDays}',
        icon: Icons.local_shipping_outlined,
        fg: AppColors.textDark,
        bg: AppColorsExtra.chipGrey,
        fontSize: 11,
      );
    } else {
      secondChip = StatusPill(
        text: 'On-Time ${s.onTimePct ?? 100}%',
        icon: Icons.check_circle_outline,
        fg: AppColors.success,
        bg: AppColorsExtra.successSoft,
        border: AppColorsExtra.successBorder,
        fontSize: 11,
      );
    }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: s.preferred
                              ? AppColors.lightBlue
                              : AppColorsExtra.chipGrey,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          s.category,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: s.preferred
                                ? AppColors.deepBlue
                                : AppColors.textDark.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: const BoxDecoration(
                    color: AppColorsExtra.panelGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_right,
                      size: 19.sp, color: AppColors.textDark),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.person_outline, size: 15.sp, color: AppColors.grey),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    '${s.contact} · ${s.phone} · ${s.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textDark.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                if (openPos > 0)
                  StatusPill(
                    text: '$openPos Open PO${openPos == 1 ? '' : 's'} '
                        '(${formatCad(openValue, decimals: 0)} CAD)',
                    dot: true,
                    fg: AppColorsExtra.amberText,
                    bg: AppColorsExtra.amberSoft,
                    border: AppColorsExtra.amberBorder,
                    fontSize: 11,
                  )
                else
                  const StatusPill(
                    text: 'No Open POs',
                    fg: AppColors.grey,
                    bg: AppColorsExtra.chipGrey,
                    fontSize: 11,
                  ),
                secondChip,
              ],
            ),
            SizedBox(height: 10.h),
            const Divider(color: AppColorsExtra.panelBorder),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Purchased: '),
                      TextSpan(
                        text: '${formatCad(s.totalPurchased)} CAD',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: ' · ${s.lastOrder}'),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                StatusPill(
                  text: '${s.terms} Terms',
                  fg: AppColors.textDark,
                  bg: AppColorsExtra.chipGrey,
                  fontSize: 10.5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
