import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/shared_widgets.dart';
import 'staff_models.dart';
import 'staff_store.dart';
import 'staff_widgets.dart';

/// Bottom sheet: choose an active employee (opens their permissions from
/// the More menu). Returns the chosen member or null.
class PickStaffSheet extends StatelessWidget {
  const PickStaffSheet({super.key});

  static Future<StaffMember?> open() => Get.bottomSheet<StaffMember>(
    const PickStaffSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
  );

  @override
  Widget build(BuildContext context) {
    final staff = StaffStore.to.staff.where((s) => s.active).toList();
    return SheetFrame(
      heightFactor: 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choose employee',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SheetCloseButton(onTap: Get.back),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Open the Permissions Manager for an active employee.',
            style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
          ),
          SizedBox(height: 14.h),
          for (final m in staff)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Material(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  onTap: () => Get.back(result: m),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        InitialsAvatar(initials: m.initials, size: 40),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              RoleChip(m.title),
                            ],
                          ),
                        ),
                        Text(
                          '${m.permissions.length}/${PermissionCatalog.total}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.chevron_right,
                          size: 20.sp,
                          color: AppColors.greyLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
