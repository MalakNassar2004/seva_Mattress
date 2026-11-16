import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'staff_controller.dart';
import 'staff_mock.dart';
import 'staff_models.dart';
import 'staff_widgets.dart';

/// Staff list (owner). Opened from the More tab, so it shows the owner
/// bottom navigation with More selected.
class StaffView extends GetView<StaffController> {
  const StaffView({super.key});

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
                    Obx(_buildHeader),
                    SizedBox(height: 14.h),
                    Obx(_buildStats),
                    SizedBox(height: 14.h),
                    _buildSearch(),
                    SizedBox(height: 12.h),
                    Obx(_buildRoleChips),
                    SizedBox(height: 10.h),
                    Obx(_buildStatusChips),
                    SizedBox(height: 14.h),
                    Obx(_buildList),
                    SizedBox(height: 4.h),
                    const AuditNote(
                      'Role permission changes recorded in audit log',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: PrimaryArrowButton(
                  label: '+ Add Employee',
                  leadingIcon: Icons.person_add_alt_1_outlined,
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
            SizedBox(width: 8.w),
            const Spacer(),
            const Flexible(
              flex: 4,
              child: StatusPill(
                text: StaffMock.store,
                icon: Icons.storefront_outlined,
                fg: AppColors.textDark,
                bg: AppColors.white,
                border: AppColors.border,
                fontSize: 11,
              ),
            ),
            SizedBox(width: 6.w),
            const StatusPill(
              text: 'PCI L1',
              icon: Icons.lock,
              fg: AppColors.deepBlue,
              bg: AppColors.white,
              border: AppColors.border,
              fontSize: 11,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        PageTitle(
          title: 'Staff',
          subtitle: 'Team Directory & Access Management · Surrey, BC',
          badge: StatusPill(
            text: '${controller.store.staff.length} Members',
            fg: AppColors.deepBlue,
            bg: AppColors.lightBlue,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  // ---------------- Stats ----------------
  Widget _buildStats() {
    Widget stat({
      required Widget label,
      required String value,
      required String caption,
      Color valueColor = AppColors.textDark,
    }) {
      return Expanded(
        child: Column(
          children: [
            label,
            SizedBox(height: 4.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              caption,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: AppColors.textDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }

    Widget caption(Widget lead, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        lead,
        SizedBox(width: 5.w),
        Caption(text),
      ],
    );

    Widget divider() =>
        Container(width: 1, height: 52.h, color: AppColorsExtra.panelBorder);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          stat(
            label: caption(
              Icon(
                Icons.group_outlined,
                size: 14.sp,
                color: AppColors.deepBlue,
              ),
              'Total',
            ),
            value: '${controller.activeCount}',
            caption: 'Active Staff',
          ),
          divider(),
          stat(
            label: caption(
              Container(
                width: 7.w,
                height: 7.w,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              'On Shift',
            ),
            value: '${controller.onShiftCount}',
            caption: 'On Clock Now',
            valueColor: AppColors.success,
          ),
          divider(),
          stat(
            label: caption(
              Icon(
                Icons.badge_outlined,
                size: 14.sp,
                color: AppColors.deepBlue,
              ),
              'Roles',
            ),
            value: '${StaffRole.values.length}',
            caption: 'Defined Tiers',
          ),
        ],
      ),
    );
  }

  // ---------------- Search & filters ----------------
  Widget _buildSearch() {
    return AppSearchBar(
      hint: 'Search employee name, role, email...',
      onChanged: controller.onSearchChanged,
      onFilterTap: controller.onFiltersPressed,
    );
  }

  Widget _buildRoleChips() {
    final options = <StaffRole?>[null, ...StaffRole.values];
    return FilterChipBar(
      options: [
        for (final r in options)
          FilterOption(
            r == null ? 'All' : r.plural,
            count: controller.countFor(r),
          ),
      ],
      selectedIndex: options.indexOf(controller.role.value),
      onSelected: (i) => controller.selectRole(options[i]),
    );
  }

  Widget _buildStatusChips() {
    final sel = controller.status.value;
    Widget chip(StaffStatusFilter f, String label, int count, Color dot) {
      final active = f == sel;
      return GestureDetector(
        onTap: () => controller.selectStatus(f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: active
                ? AppColorsExtra.successSoft
                : AppColorsExtra.panelGrey,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: active
                  ? AppColorsExtra.successBorder
                  : AppColorsExtra.panelBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7.w,
                height: 7.w,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              SizedBox(width: 6.w),
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? AppColors.textDark : AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        chip(
          StaffStatusFilter.active,
          'Active',
          controller.activeCount,
          AppColors.success,
        ),
        chip(
          StaffStatusFilter.deactivated,
          'Deactivated',
          controller.deactivatedCount,
          AppColors.greyLight,
        ),
      ],
    );
  }

  // ---------------- List ----------------
  Widget _buildList() {
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
              child: Icon(
                Icons.badge_outlined,
                size: 28.sp,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'No employees match',
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
          .map(
            (m) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _StaffCard(
                member: m,
                onTap: () => controller.onStaffTap(m),
                onActiveChanged: (v) => controller.onActiveChanged(m, v),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.member,
    required this.onTap,
    required this.onActiveChanged,
  });

  final StaffMember member;
  final VoidCallback onTap;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final off = !m.active;
    final Color dot = off
        ? AppColors.greyLight
        : (m.onRoute != null ? AppColors.primaryBlue : AppColors.success);
    final faded = AppColors.greyLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 10.w, 12.h),
        decoration: BoxDecoration(
          color: off ? AppColors.white.withValues(alpha: 0.6) : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
          boxShadow: off ? null : AppShadows.small,
        ),
        child: Column(
          children: [
            Row(
              children: [
                InitialsAvatar(
                  initials: m.initials,
                  size: 48,
                  bg: off ? AppColorsExtra.chipGrey : AppColors.lightBlue,
                  fg: off ? AppColors.greyLight : AppColors.deepBlue,
                  dotColor: dot,
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
                              m.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: off ? faded : AppColors.textDark,
                              ),
                            ),
                          ),
                          if (m.starred && !off) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.star_rounded,
                              size: 18.sp,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 5.h),
                      RoleChip(m.title, muted: off),
                    ],
                  ),
                ),
                AppSwitch(value: m.active, onChanged: onActiveChanged),
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right,
                  size: 22.sp,
                  color: off ? faded : AppColors.grey,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            const Divider(color: AppColorsExtra.panelBorder),
            SizedBox(height: 10.h),
            _buildFooter(off, faded),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool off, Color faded) {
    final m = member;
    final IconData icon;
    final String left;
    Color leftColor = AppColors.textDark.withValues(alpha: 0.8);
    if (off) {
      icon = Icons.person_off_outlined;
      left = 'Deactivated · ${m.deactivatedOn ?? '—'}';
      leftColor = faded;
    } else if (m.onRoute != null) {
      icon = Icons.local_shipping_outlined;
      left = m.onRoute!;
      leftColor = AppColors.primaryBlue;
    } else {
      icon = Icons.schedule;
      left = 'Last active ${m.lastActive}';
    }

    final Widget right;
    if (off) {
      right = Text(
        'Suspended',
        style: TextStyle(fontSize: 12.sp, color: faded),
      );
    } else if (m.routeProgress != null) {
      right = StatusPill(
        text: m.routeProgress!,
        fg: AppColors.deepBlue,
        bg: AppColorsExtra.infoBg,
        fontSize: 11,
      );
    } else {
      right = Text(
        m.location,
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textDark.withValues(alpha: 0.7),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(right: 4.w),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: leftColor),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: m.onRoute != null && !off
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: leftColor,
              ),
            ),
          ),
          right,
        ],
      ),
    );
  }
}
