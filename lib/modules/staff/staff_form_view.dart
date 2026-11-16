import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'staff_form_controller.dart';
import 'staff_mock.dart';
import 'staff_models.dart';

/// Add / Edit Staff.
class StaffFormView extends GetView<StaffFormController> {
  const StaffFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                child: _buildHeader(),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                  children: [
                    _buildPersonalCard(),
                    SizedBox(height: 14.h),
                    Obx(_buildRoleCard),
                    SizedBox(height: 14.h),
                    Obx(_buildAccessCard),
                    SizedBox(height: 14.h),
                    Obx(_buildPermissionsCard),
                    Obx(() {
                      final m = controller.created.value;
                      if (m == null) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(top: 14.h),
                        child: _buildHandoverCard(),
                      );
                    }),
                    SizedBox(height: 16.h),
                    const AuditNote(
                      'This action is logged under Owner PIN '
                      '${StaffMock.ownerPin}.',
                    ),
                    if (controller.isEdit &&
                        (controller.editing?.active ?? false)) ...[
                      SizedBox(height: 16.h),
                      SizedBox(
                        width: double.infinity,
                        child: SoftButton(
                          label: 'Deactivate account',
                          icon: Icons.person_off_outlined,
                          height: 50,
                          radius: 16,
                          fontSize: 14,
                          fg: AppColors.danger,
                          borderColor: AppColors.danger,
                          onTap: controller.onDeactivatePressed,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
                child: Obx(
                  () => PrimaryArrowButton(
                    label: controller.created.value != null
                        ? 'Done'
                        : controller.isEdit
                        ? 'Save changes'
                        : 'Create account',
                    leadingIcon: controller.created.value != null
                        ? Icons.check_circle_outline
                        : Icons.person_add_alt_1_outlined,
                    onPressed: controller.onSubmit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Row(
      children: [
        BackPill(label: 'Staff', onTap: controller.onBackPressed),
        Expanded(
          child: Column(
            children: [
              Text(
                controller.isEdit ? 'Edit Employee' : 'Add Employee',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Owner Authorization',
                style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
              ),
            ],
          ),
        ),
        const StatusPill(
          text: 'Surrey POS',
          icon: Icons.shield,
          fg: AppColors.deepBlue,
          bg: AppColorsExtra.chipGrey,
          fontSize: 10.5,
        ),
      ],
    );
  }

  // ---------------- Personal ----------------
  Widget _buildPersonalCard() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(
            icon: Icons.badge_outlined,
            title: 'Personal Information',
          ),
          SizedBox(height: 14.h),
          _field(
            'name',
            'Full name',
            controller.nameController,
            Icons.person_outline,
            'e.g. Liam Bennett',
            TextInputType.name,
          ),
          _field(
            'email',
            'Work email',
            controller.emailController,
            Icons.mail_outline,
            'name@sevasleep.ca',
            TextInputType.emailAddress,
          ),
          _field(
            'phone',
            'Mobile phone',
            controller.phoneController,
            Icons.phone_outlined,
            '(604) 555-0000',
            TextInputType.phone,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String key,
    String label,
    TextEditingController tc,
    IconData icon,
    String hint,
    TextInputType keyboard, {
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12.h),
      child: Obx(() {
        final err = controller.errors[key];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledInput(
              controller: tc,
              label: '$label *',
              hint: hint,
              prefixIcon: icon,
              keyboardType: keyboard,
              onChanged: (_) => controller.clearError(key),
            ),
            if (err != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h, left: 4.w),
                child: Text(
                  err,
                  style: TextStyle(fontSize: 11.5.sp, color: AppColors.danger),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ---------------- Role ----------------
  Widget _buildRoleCard() {
    final selected = controller.role.value;
    Widget card(StaffRole r) => Expanded(
      child: _RoleCard(
        role: r,
        selected: r == selected,
        onTap: () => controller.selectRole(r),
      ),
    );

    return SectionCard(
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
                      'Assigned Role',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Defines baseline abilities & refund limits',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.manage_accounts_outlined,
                size: 22.sp,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                card(StaffRole.manager),
                SizedBox(width: 10.w),
                card(StaffRole.cashier),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                card(StaffRole.warehouse),
                SizedBox(width: 10.w),
                card(StaffRole.driver),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Access ----------------
  Widget _buildAccessCard() {
    final visible = controller.pinVisible.value;
    final pin = controller.pin.value;
    final isActive = controller.active.value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.dialpad,
                  size: 18.sp,
                  color: AppColors.primaryBlue,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access & POS PIN',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Sign-in credentials for terminals & mobile',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.lock_outline, size: 20.sp, color: AppColors.grey),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Temporary PIN (24h validity)',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50.h,
                  padding: EdgeInsets.only(left: 14.w, right: 6.w),
                  decoration: BoxDecoration(
                    color: AppColorsExtra.panelGrey,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColorsExtra.panelBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          visible
                              ? pin.split('').join('  ')
                              : '•  •  •  •  •  •',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: controller.togglePinVisible,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          visible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20.sp,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              SoftButton(
                label: 'Generate',
                icon: Icons.refresh,
                height: 50,
                radius: 12,
                onTap: controller.generatePin,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'The temporary PIN expires in 24 hours. The employee sets a '
            'permanent PIN and password at first sign-in.',
            style: TextStyle(
              fontSize: 11.5.sp,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account status',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isActive
                          ? 'Active · Sign-in allowed'
                          : 'Deactivated · Sign-in blocked',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.primaryBlue
                            : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              AppSwitch(value: isActive, onChanged: controller.toggleActive),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Permissions preview ----------------
  Widget _buildPermissionsCard() {
    final granted = controller.permissions.length;
    final preview = controller.previewPermissions;
    final remaining = granted - preview.length;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Permissions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: StatusPill(
                  text: '$granted of ${PermissionCatalog.total} permissions',
                  fg: AppColors.deepBlue,
                  bg: AppColors.lightBlue,
                  fontSize: 11,
                ),
              ),
              SizedBox(width: 8.w),
              const Spacer(),
              Icon(Icons.tune, size: 20.sp, color: AppColors.grey),
            ],
          ),
          SizedBox(height: 12.h),
          if (granted == 0)
            Text(
              'No permissions granted yet.',
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final p in preview)
                  StatusPill(
                    text: p.label,
                    icon: Icons.check_circle,
                    fg: AppColors.deepBlue,
                    bg: AppColorsExtra.panelGrey,
                    border: AppColorsExtra.panelBorder,
                    fontSize: 11.5,
                  ),
                if (remaining > 0)
                  StatusPill(
                    text: '+$remaining more',
                    fg: AppColors.grey,
                    bg: AppColorsExtra.chipGrey,
                    fontSize: 11.5,
                  ),
              ],
            ),
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.onCustomizePermissions,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Customize permissions',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward,
                    size: 16.sp,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Handover (after create) ----------------
  Widget _buildHandoverCard() {
    return SectionCard(
      color: AppColorsExtra.infoBg,
      borderColor: AppColorsExtra.infoBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_outlined, size: 18.sp, color: AppColors.deepBlue),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Account created',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Caption('Quick invite', color: AppColors.deepBlue),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 10.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColorsExtra.infoBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Credentials',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.grey,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        controller.credentials,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                SoftButton(
                  label: 'Copy',
                  icon: Icons.copy_rounded,
                  height: 38,
                  radius: 10,
                  fg: AppColors.deepBlue,
                  borderColor: AppColorsExtra.infoBorder,
                  onTap: controller.onCopyCredentials,
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Share credentials securely. The employee sets a new password '
            'at first sign-in.',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.35,
              color: AppColors.textDark.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable role card (Manager, Cashier, Warehouse, Delivery Driver).
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final StaffRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? AppColorsExtra.infoBg : AppColorsExtra.panelGrey,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected
                ? AppColors.primaryBlue
                : AppColorsExtra.panelBorder,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected ? AppShadows.small : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryBlue : AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: selected
                        ? null
                        : Border.all(color: AppColorsExtra.panelBorder),
                  ),
                  child: Icon(
                    role.icon,
                    size: 18.sp,
                    color: selected ? AppColors.white : AppColors.textDark,
                  ),
                ),
                const Spacer(),
                RadioDot(selected: selected, size: 20),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              role.label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.primaryBlue : AppColors.textDark,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              role.description,
              style: TextStyle(
                fontSize: 11.sp,
                height: 1.3,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
