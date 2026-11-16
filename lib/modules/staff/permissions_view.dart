import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'permissions_controller.dart';
import 'staff_mock.dart';
import 'staff_models.dart';
import 'staff_widgets.dart';

/// Permissions Manager for one employee.
class PermissionsView extends GetView<PermissionsController> {
  const PermissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                  children: [
                    _buildTopBar(),
                    SizedBox(height: 12.h),
                    Text(
                      'Permissions Manager',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.6,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(_buildEmployeeCard),
                    SizedBox(height: 12.h),
                    _buildBanner(),
                    SizedBox(height: 14.h),
                    Obx(_buildSummary),
                    SizedBox(height: 12.h),
                    for (final g in PermissionCatalog.groups) ...[
                      Obx(() => _buildGroup(g)),
                      SizedBox(height: 12.h),
                    ],
                    const AuditNote(
                      'PCI-DSS Level 1 Encrypted · Role Governance',
                    ),
                  ],
                ),
              ),
              Obx(_buildStickyBar),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildTopBar() {
    return Row(
      children: [
        BackPill(label: 'Staff', onTap: controller.onBackPressed),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            '${StaffMock.store} · CAD',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard() {
    final m = controller.member;
    final t = controller.template.value;
    return SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(
                initials: m.initials,
                size: 50,
                bg: AppColors.deepBlue,
                fg: AppColors.white,
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
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        RoleChip(m.role.label),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      '#${m.id} · ${StaffMock.store}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Caption('Base profile'),
              SizedBox(width: 12.w),
              Expanded(
                child: PopupMenuButton<PermissionTemplate>(
                  onSelected: controller.applyTemplate,
                  position: PopupMenuPosition.under,
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  itemBuilder: (_) => [
                    for (final tpl in PermissionTemplate.values)
                      PopupMenuItem(
                        value: tpl,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tpl.label,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: tpl == t
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: tpl == t
                                      ? AppColors.primaryBlue
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${tpl.permissions.length}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsExtra.panelGrey,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColorsExtra.panelBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 18.sp,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Start from template: ${t?.label ?? 'Custom'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 22.sp,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.infoBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsExtra.infoBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt, size: 18.sp, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Changes apply instantly on all devices, including signed-in '
              'sessions.',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.deepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final pending = controller.pendingCount;
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: const BoxDecoration(
            color: AppColors.deepBlue,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            '${controller.granted.length} of ${PermissionCatalog.total} '
            'Permissions Active',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (pending > 0)
          StatusPill(
            text: '$pending change${pending == 1 ? '' : 's'} pending',
            dot: true,
            fg: AppColorsExtra.amberText,
            bg: AppColorsExtra.amberSoft,
            border: AppColorsExtra.amberBorder,
            fontSize: 11,
          ),
      ],
    );
  }

  // ---------------- Groups ----------------
  Widget _buildGroup(PermissionGroup g) {
    final open = controller.expanded.contains(g.title);
    final active = controller.activeIn(g);
    final none = active == 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => controller.toggleGroup(g),
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(g.icon, size: 20.sp, color: AppColors.deepBlue),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          g.subtitle,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  StatusPill(
                    text: '$active of ${g.items.length} Active',
                    fg: none ? AppColors.grey : AppColors.deepBlue,
                    bg: none ? AppColorsExtra.chipGrey : AppColors.lightBlue,
                    fontSize: 10.5,
                  ),
                  SizedBox(width: 4.w),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 22.sp,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            for (final p in g.items) _buildRow(p),
        ],
      ),
    );
  }

  Widget _buildRow(Permission p) {
    final on = controller.isOn(p.id);
    final changed = controller.isChanged(p);
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColorsExtra.panelBorder)),
      ),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (changed)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (p.sensitive) const SensitiveTag(),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      p.helper,
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.3,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              AppSwitch(value: on, onChanged: (v) => controller.toggle(p, v)),
            ],
          ),
          if (p.hasDiscountCap && on) ...[
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.only(right: 6.w),
              child: _buildCapInput(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 6.h, 6.w, 6.h),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Max discount',
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Container(
            width: 84.w,
            height: 36.h,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColorsExtra.infoBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.capController,
                    onChanged: controller.onCapChanged,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepBlue,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Text(
                  ' %',
                  style: TextStyle(
                    fontSize: 13.sp,
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

  // ---------------- Sticky bar ----------------
  Widget _buildStickyBar() {
    final pending = controller.pendingCount;
    final enabled = pending > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SoftButton(
            label: 'Reset',
            icon: Icons.restart_alt,
            height: 54,
            radius: 16,
            fontSize: 14,
            onTap: controller.onReset,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: SoftButton(
                label: enabled ? 'Save changes ($pending)' : 'Save changes',
                icon: Icons.sync,
                filled: true,
                height: 54,
                radius: 16,
                fontSize: 15,
                onTap: controller.onSave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
