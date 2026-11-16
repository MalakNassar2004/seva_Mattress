import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';

/// Light-blue rounded role label ("Store Manager", "Cashier").
class RoleChip extends StatelessWidget {
  const RoleChip(this.text, {super.key, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: muted ? AppColorsExtra.chipGrey : AppColors.lightBlue,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: muted ? AppColors.grey : AppColors.deepBlue,
        ),
      ),
    );
  }
}

/// Small amber "Sensitive" label with a warning icon.
class SensitiveTag extends StatelessWidget {
  const SensitiveTag({super.key, this.text = 'Sensitive'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColorsExtra.amberSoft,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColorsExtra.amberBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 12.sp,
            color: AppColorsExtra.amberText,
          ),
          SizedBox(width: 3.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColorsExtra.amberText,
            ),
          ),
        ],
      ),
    );
  }
}
