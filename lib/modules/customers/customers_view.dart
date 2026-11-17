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
import '../owner_shell/owner_shell_controller.dart';
import 'customer_models.dart';
import 'customers_controller.dart';

/// Customers list (owner). Opened from the More tab, so it shows the owner
/// bottom navigation with More selected. Set showBottomNav to false if the
/// page is hosted inside a screen that already draws the navigation.
class CustomersView extends GetView<CustomersController> {
  const CustomersView({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 14.h),
                      OwnerSearchField(
                        hint: 'Search name, phone, email or city',
                        onChanged: controller.onSearchChanged,
                        onScan: controller.onScanPressed,
                      ),
                      SizedBox(height: 12.h),
                      _buildFilters(),
                      SizedBox(height: 14.h),
                      Obx(() {
                        final list = controller.customers;
                        if (list.isEmpty) return _buildEmpty();
                        return Column(
                          children: list
                              .map(
                                (c) => Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: _buildCustomerCard(c),
                                ),
                              )
                              .toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: PrimaryArrowButton(
                  label: '+ Add Customer',
                  leadingIcon: Icons.person_add_alt_1_outlined,
                  onPressed: controller.onAddCustomerPressed,
                ),
              ),
              if (showBottomNav)
                OwnerBottomNav(
                  currentIndex: OwnerShellController.moreTab,
                  moreBadge: OwnerShellController.moreBadge,
                  onTap: controller.onNavTap,
                )
              else
                SizedBox(height: 8.h),
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
            WhitePill(
              onTap: controller.onBackPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left,
                      size: 22.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 2.w),
                  Text(
                    'More',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Obx(
                  () => StatusPill(
                    text: '${controller.totalCount.value} Clients',
                    dot: true,
                    fg: AppColors.deepBlue,
                    bg: AppColors.lightBlue,
                    border: AppColorsExtra.infoBorder,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            CircleIconButton(
              icon: Icons.sync,
              iconColor: AppColors.primaryBlue,
              onTap: controller.onSyncPressed,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Text(
          'Customers',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Owner Mode · CAD Currency Enabled',
          style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(
        () => Row(
          children: List.generate(CustomersController.filters.length, (i) {
            final selected = controller.filterIndex.value == i;
            final isBalance = i == CustomersController.balanceFilter;

            final Color bg;
            final Color fg;
            final Color border;
            if (isBalance) {
              bg = selected ? AppColors.warning : AppColors.warningBg;
              fg = selected ? AppColors.white : AppColors.warning;
              border = AppColorsExtra.warningBorder;
            } else {
              bg = selected ? AppColors.primaryBlue : AppColors.white;
              fg = selected ? AppColors.white : AppColors.textDark;
              border = selected ? AppColors.primaryBlue : AppColors.border;
            }

            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => controller.selectFilter(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBalance) ...[
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: BoxDecoration(
                            color: fg,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      Text(
                        CustomersController.filters[i],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Shown when the list is empty. Called inside an Obx, so the observables
  /// read here are tracked.
  Widget _buildEmpty() {
    if (controller.isLoading.value) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final String message;
    if (controller.loadError.value != null) {
      message = 'Could not load the customers. Check your connection.';
    } else if (controller.totalCount.value == 0) {
      message = 'No customers yet. Tap "+ Add Customer" to add the first one.';
    } else if (controller.filterIndex.value ==
        CustomersController.balanceFilter) {
      message = 'No customers with a balance owing.';
    } else {
      message = 'No customers match your search.';
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                size: 28.sp, color: AppColors.primaryBlue),
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Customer card ----------------
  Widget _buildCustomerCard(CustomerItem c) {
    return GestureDetector(
      onTap: () => controller.onCustomerTap(c),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColorsExtra.infoBorder),
                  ),
                  child: Text(
                    c.initials,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (c.isVip) ...[
                            SizedBox(width: 6.w),
                            Icon(Icons.star,
                                size: 16.sp, color: const Color(0xFFF59E0B)),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColorsExtra.amberBg,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                    color: AppColorsExtra.amberBorder),
                              ),
                              child: Text(
                                'VIP',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColorsExtra.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14.sp, color: AppColors.grey),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              c.city.isEmpty ? c.phone : '${c.phone} • ${c.city}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20.sp, color: AppColors.greyLight),
              ],
            ),
            SizedBox(height: 10.h),
            const Divider(),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.ordersLabel,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (c.note.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.noteIcon != null) ...[
                              Icon(
                                c.noteIcon,
                                size: 13.sp,
                                color: c.noteIsAccent
                                    ? AppColors.primaryBlue
                                    : AppColors.grey,
                              ),
                              SizedBox(width: 4.w),
                            ],
                            Flexible(
                              child: Text(
                                c.note,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  height: 1.25,
                                  fontWeight: c.noteIsAccent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: c.noteIsAccent
                                      ? AppColors.primaryBlue
                                      : AppColors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (c.orderCount > 0) ...[
                  SizedBox(width: 8.w),
                  c.balanceOwing == null
                      ? StatusPill(
                          text: 'Paid in Full',
                          icon: Icons.check_circle,
                          fg: AppColors.success,
                          bg: AppColors.successBg,
                          border: AppColorsExtra.successBorder,
                        )
                      : Flexible(
                          child: StatusPill(
                            text:
                                'Balance Owing: ${formatCad(c.balanceOwing!)} CAD',
                            icon: Icons.warning_amber_rounded,
                            fg: AppColors.warning,
                            bg: AppColors.warningBg,
                            border: AppColorsExtra.warningBorder,
                            maxLines: 2,
                          ),
                        ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}