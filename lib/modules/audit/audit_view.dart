import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/dates.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'audit_controller.dart';
import 'audit_models.dart';
import 'audit_widgets.dart';

/// Read-only Audit Log (owner). Opened from the More tab.
class AuditView extends GetView<AuditController> {
  const AuditView({super.key});

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
                    AppSearchBar(
                      hint: 'Search events, employee, order, SKU...',
                      onChanged: controller.onSearchChanged,
                      onFilterTap: controller.onFiltersPressed,
                    ),
                    SizedBox(height: 12.h),
                    Obx(_buildActionChips),
                    SizedBox(height: 10.h),
                    Obx(_buildSecondaryFilters),
                    SizedBox(height: 14.h),
                    Obx(_buildGroups),
                    SizedBox(height: 4.h),
                    const AuditNote(
                      'Entries are cryptographically signed and cannot be edited',
                      icon: Icons.verified_user_outlined,
                    ),
                  ],
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
            const StatusPill(
              text: 'PCI-DSS L1',
              icon: Icons.lock,
              fg: AppColors.deepBlue,
              bg: AppColors.white,
              border: AppColors.border,
              fontSize: 11,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        const PageTitle(
          title: 'Audit Log',
          subtitle: 'Store Activity Ledger · Surrey Flagship',
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h,
          children: const [
            StatusPill(
              text: 'Read-only log',
              icon: Icons.lock_outline,
              fg: AppColors.deepBlue,
              bg: AppColors.lightBlue,
              border: AppColorsExtra.infoBorder,
              fontSize: 11.5,
            ),
            StatusPill(
              text: 'Owner Clearance',
              icon: Icons.verified_user_outlined,
              fg: AppColors.textDark,
              bg: AppColorsExtra.chipGrey,
              fontSize: 11.5,
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- Filters ----------------
  Widget _buildActionChips() {
    final options = <AuditAction?>[null, ...AuditAction.values];
    return FilterChipBar(
      options: [
        for (final a in options)
          FilterOption(
            a == null ? 'All Actions' : a.label,
            count: controller.countFor(a),
          ),
      ],
      selectedIndex: options.indexOf(controller.action.value),
      onSelected: (i) => controller.selectAction(options[i]),
    );
  }

  Widget _buildSecondaryFilters() {
    final users = <String?>[null, ...controller.users];
    final user = controller.user.value;
    final date = controller.dateFilter.value;
    return Row(
      children: [
        Flexible(
          child: MenuPill<String?>(
            label: user ?? 'All Users (${users.length - 1})',
            icon: Icons.person_outline,
            items: users,
            selected: user,
            itemLabel: (u) => u ?? 'All Users',
            onSelected: controller.selectUser,
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: MenuPill<AuditDateFilter>(
            label: 'Date: ${date.label}',
            icon: Icons.calendar_today_outlined,
            items: AuditDateFilter.values,
            selected: date,
            itemLabel: (d) => d.label,
            onSelected: controller.selectDate,
          ),
        ),
      ],
    );
  }

  // ---------------- List ----------------
  Widget _buildGroups() {
    final groups = controller.groups;
    if (groups.isEmpty) {
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
                Icons.history,
                size: 28.sp,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'No events match these filters',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (day, events) in groups) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 10.h),
            child: Row(
              children: [
                Expanded(child: Caption(formatDayHeader(day))),
                Text(
                  '${events.length} event${events.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
          for (final e in events)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _EventCard(
                event: e,
                onTap: () => controller.onEventTap(e),
              ),
            ),
        ],
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final AuditEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final roleText = e.employeeId == null
        ? ' (${e.actorRole})'
        : ' (${e.actorRole} · #${e.employeeId})';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 10.w, 14.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuditAvatar(event: e),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: e.actor,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: roleText,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: e.isOwner
                                ? AppColors.primaryBlue
                                : AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    e.sentence,
                    style: TextStyle(
                      fontSize: 14.5.sp,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (e.newValue != null) ...[
                    SizedBox(height: 8.h),
                    AuditValueChip(event: e),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 1.h),
                        child: Icon(
                          Icons.schedule,
                          size: 14.sp,
                          color: AppColors.grey,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          [
                            formatTime(e.time),
                            if (e.context != null) e.context,
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.35,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20.sp, color: AppColors.greyLight),
          ],
        ),
      ),
    );
  }
}
