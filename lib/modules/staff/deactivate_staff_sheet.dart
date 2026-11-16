import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'staff_mock.dart';
import 'staff_models.dart';

/// Bottom sheet: "Deactivate Sara Lee?". Returns true when the owner
/// confirms. The caller does the actual deactivation.
class DeactivateStaffSheet extends StatelessWidget {
  const DeactivateStaffSheet({super.key, required this.member});

  final StaffMember member;

  static Future<bool> open(StaffMember member) async {
    final result = await Get.bottomSheet<bool>(
      DeactivateStaffSheet(member: member),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final m = member;
    final first = m.name.split(' ').first;
    return SheetFrame(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DangerButton(
            label: 'Deactivate',
            onTap: () => Get.back(result: true),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              label: 'Cancel',
              height: 50,
              radius: 16,
              fontSize: 14.5,
              onTap: () => Get.back(result: false),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: StatusPill(
                  text: 'SECURITY OVERRIDE · OWNER ACTION',
                  dot: true,
                  fg: AppColorsExtra.amber,
                  bg: AppColorsExtra.amberSoft,
                  border: AppColorsExtra.amberBorder,
                  fontSize: 10.5,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 8.w),
              const Spacer(),
              SheetCloseButton(onTap: () => Get.back(result: false)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColorsExtra.dangerBorder),
                ),
                child: Icon(
                  Icons.lock_person_outlined,
                  size: 24.sp,
                  color: AppColors.danger,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deactivate ${m.name}?',
                      style: TextStyle(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '$first will be signed out of all devices immediately. '
                      'Active register sessions will lock and the POS PIN '
                      'will be revoked.',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        height: 1.4,
                        color: AppColors.textDark.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildEmployeeCard(),
          SizedBox(height: 12.h),
          _buildConsequences(),
          SizedBox(height: 14.h),
          AuditNote(
            'This action is recorded in the audit log under Owner PIN '
            '${StaffMock.ownerPin}.',
            icon: Icons.lock_outline,
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard() {
    final m = member;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InitialsAvatar(initials: m.initials, size: 40),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: m.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: '  ·  ${m.title}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Employee ID: #${m.id} · ${StaffMock.store}',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (m.onShift)
                const StatusPill(
                  text: 'Active Shift',
                  fg: AppColors.success,
                  bg: AppColorsExtra.successSoft,
                  border: AppColorsExtra.successBorder,
                  fontSize: 10.5,
                ),
            ],
          ),
          SizedBox(height: 10.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.schedule, size: 15.sp, color: AppColors.grey),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Last active ${m.lastActive}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                m.location,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColorsExtra.amberText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsequences() {
    Widget line(IconData icon, String text) => Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15.sp, color: AppColorsExtra.amber),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5.sp,
                height: 1.35,
                color: AppColors.textDark.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: AppColorsExtra.warningSoft,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsExtra.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16.sp,
                color: AppColorsExtra.amber,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Immediate Operational Consequences',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColorsExtra.amber,
                  ),
                ),
              ),
            ],
          ),
          line(
            Icons.power_settings_new,
            'Signed out of every terminal and mobile session',
          ),
          line(
            Icons.assignment_ind_outlined,
            'Pending approval requests will be reassigned to Owner',
          ),
          line(
            Icons.verified_user_outlined,
            'Historical sales, commissions and shifts remain in the audit log',
          ),
        ],
      ),
    );
  }
}

/// Red filled button with an arrow, used for destructive confirmations.
class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 22.sp,
                  color: AppColors.white,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward, size: 20.sp, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
