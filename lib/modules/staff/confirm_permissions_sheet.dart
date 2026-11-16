import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'permissions_controller.dart';
import 'staff_mock.dart';
import 'staff_models.dart';

/// Bottom sheet: "Confirm Permission Changes". Lists exactly what will
/// change. Returns true when the owner applies them.
class ConfirmPermissionsSheet extends StatelessWidget {
  const ConfirmPermissionsSheet({
    super.key,
    required this.member,
    required this.diffs,
  });

  final StaffMember member;
  final List<PermissionDiff> diffs;

  static Future<bool> open(
    StaffMember member,
    List<PermissionDiff> diffs,
  ) async {
    final result = await Get.bottomSheet<bool>(
      ConfirmPermissionsSheet(member: member, diffs: diffs),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final n = diffs.length;
    return SheetFrame(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryArrowButton(
            label: 'Authorize & Apply Changes',
            leadingIcon: Icons.sync,
            onPressed: () => Get.back(result: true),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              label: 'Review More / Cancel',
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
                  text: 'OWNER SECURITY ACTION',
                  icon: Icons.shield,
                  fg: AppColors.deepBlue,
                  bg: AppColors.lightBlue,
                  fontSize: 10.5,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(width: 8.w),
              const Spacer(),
              SheetCloseButton(onTap: () => Get.back(result: false)),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Confirm Permission Changes',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4.h),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Updating access for '),
                TextSpan(
                  text: member.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ' (${member.role.label} · #${member.id})'),
              ],
            ),
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textDark.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.infoBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColorsExtra.infoBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt, size: 20.sp, color: AppColors.primaryBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$n permission${n == 1 ? '' : 's'} modified. ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepBlue,
                          ),
                        ),
                        const TextSpan(
                          text:
                              'Changes apply instantly on all devices, '
                              'including signed-in sessions.',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      height: 1.4,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              const Expanded(child: Caption('Configuration audit diff')),
              Text(
                'Live Sync',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          for (final d in diffs) ...[_DiffRow(diff: d), SizedBox(height: 10.h)],
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.segmentBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user, size: 16.sp, color: AppColors.grey),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'This change is permanently recorded in the audit log '
                    'under Owner PIN ${StaffMock.ownerPin}.',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.diff});

  final PermissionDiff diff;

  @override
  Widget build(BuildContext context) {
    final d = diff;
    final StatusPill pill;
    Color toColor = AppColors.textDark;
    switch (d.kind) {
      case DiffKind.granted when d.permission.sensitive:
        pill = const StatusPill(
          text: 'Sensitive Action',
          icon: Icons.warning_amber_rounded,
          fg: AppColorsExtra.amberText,
          bg: AppColorsExtra.amberSoft,
          border: AppColorsExtra.amberBorder,
          fontSize: 11,
        );
      case DiffKind.granted:
        pill = const StatusPill(
          text: '+ Granted',
          fg: AppColors.success,
          bg: AppColorsExtra.successSoft,
          border: AppColorsExtra.successBorder,
          fontSize: 11,
        );
      case DiffKind.revoked:
        pill = const StatusPill(
          text: '— Revoked',
          fg: AppColors.danger,
          bg: AppColorsExtra.dangerSoft,
          border: AppColorsExtra.dangerBorder,
          fontSize: 11,
        );
        toColor = AppColors.danger;
      case DiffKind.modified:
        pill = const StatusPill(
          text: 'Modified',
          icon: Icons.tune,
          fg: AppColors.deepBlue,
          bg: AppColors.lightBlue,
          border: AppColorsExtra.infoBorder,
          fontSize: 11,
        );
    }

    return Container(
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
            children: [
              Expanded(
                child: Text(
                  d.permission.label,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              pill,
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Text(
                d.from,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.grey,
                  decoration: d.kind == DiffKind.revoked
                      ? null
                      : TextDecoration.lineThrough,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Icon(
                  Icons.arrow_forward,
                  size: 14.sp,
                  color: AppColors.primaryBlue,
                ),
              ),
              Flexible(
                child: Text(
                  d.to,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: toColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
