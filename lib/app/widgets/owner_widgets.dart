import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extra.dart';
import '../theme/app_theme.dart';

/// Small rounded label: optional dot or icon + text.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.fg,
    required this.bg,
    this.border,
    this.icon,
    this.dot = false,
    this.fontSize = 11.5,
    this.maxLines = 1,
    this.letterSpacing,
  });

  final String text;
  final Color fg;
  final Color bg;
  final Color? border;
  final IconData? icon;
  final bool dot;
  final double fontSize;
  final int maxLines;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          if (icon != null) Icon(icon, size: (fontSize + 2.5).sp, color: fg),
          if (dot || icon != null) SizedBox(width: 5.w),
          Flexible(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize.sp,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: letterSpacing,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White circular icon button with a soft shadow.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textDark,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.small,
        ),
        child: Icon(icon, size: 20.sp, color: iconColor),
      ),
    );
  }
}

/// Search field with a scanner button on the right.
class OwnerSearchField extends StatelessWidget {
  const OwnerSearchField({
    super.key,
    required this.hint,
    this.onChanged,
    this.onScan,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
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
              onChanged: onChanged,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    TextStyle(fontSize: 13.sp, color: AppColors.greyLight),
              ),
            ),
          ),
          GestureDetector(
            onTap: onScan,
            child: Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.qr_code_scanner,
                  size: 18.sp, color: AppColors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

enum SegmentedStyle { solid, soft }

/// Segmented tabs.
/// solid = selected tab is filled primary blue (Inventory tabs).
/// soft  = selected tab is a white pill with blue text (Customer detail tabs).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.style = SegmentedStyle.solid,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final SegmentedStyle style;

  @override
  Widget build(BuildContext context) {
    final solid = style == SegmentedStyle.solid;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.segmentBg,
        borderRadius: BorderRadius.circular(solid ? 18.r : 16.r),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: BoxConstraints(minHeight: solid ? 38.h : 44.h),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? (solid ? AppColors.primaryBlue : AppColors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(solid ? 14.r : 12.r),
                  boxShadow: selected && !solid ? AppShadows.small : null,
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? (solid ? AppColors.white : AppColors.primaryBlue)
                        : (solid ? AppColors.textDark : AppColors.grey),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
