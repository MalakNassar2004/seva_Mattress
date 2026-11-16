import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extra.dart';
import '../theme/app_theme.dart';

/// Building blocks shared by the Orders, Quotes and Deliveries screens.

/// Thin rounded progress bar (paid progress, driver capacity).
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primaryBlue,
    this.trackColor = AppColorsExtra.progressTrack,
    this.height = 8,
  });

  /// 0..1
  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height.r),
      child: SizedBox(
        height: height.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded container for bottom sheets, with the grey handle on top.
/// [heightFactor] = share of the screen height (null = wrap content).
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.child,
    this.footer,
    this.heightFactor,
  });

  final Widget child;
  final Widget? footer;
  final double? heightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: heightFactor == null ? null : media.size.height * heightFactor!,
        constraints: BoxConstraints(maxHeight: media.size.height * 0.94),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            if (heightFactor == null)
              Flexible(child: _scroll())
            else
              Expanded(child: _scroll()),
            if (footer != null)
              Container(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  12.h,
                  20.w,
                  12.h + media.padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }

  Widget _scroll() => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
        child: child,
      );
}

/// Grey handle drawn at the top of every bottom sheet.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40.w,
      height: 4.h,
      margin: EdgeInsets.only(top: 10.h, bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}

/// Grey circular close button used in sheet headers.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: const BoxDecoration(
          color: AppColorsExtra.chipGrey,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close, size: 18.sp, color: AppColors.textDark),
      ),
    );
  }
}

/// Rounded button used for secondary actions (Send, Edit, Print Invoice...).
/// filled = primary blue background with white text.
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = false,
    this.height = 42,
    this.radius = 14,
    this.fg,
    this.borderColor,
    this.fontSize = 13,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled;
  final double height;
  final double radius;
  final Color? fg;
  final Color? borderColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = fg ?? (filled ? AppColors.white : AppColors.textDark);
    return Material(
      color: filled ? AppColors.primaryBlue : AppColors.white,
      borderRadius: BorderRadius.circular(radius.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius.r),
        child: Container(
          height: height.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius.r),
            border: filled
                ? null
                : Border.all(color: borderColor ?? AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: (fontSize + 4).sp, color: color),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circle with initials and an optional online / busy dot.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.bg = AppColors.lightBlue,
    this.fg = AppColors.deepBlue,
    this.dotColor,
  });

  final String initials;
  final double size;
  final Color bg;
  final Color fg;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.w,
      height: size.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size.w,
            height: size.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Text(
              initials,
              style: TextStyle(
                fontSize: (size * 0.34).sp,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
          if (dotColor != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: (size * 0.27).w,
                height: (size * 0.27).w,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Back pill at the top-left of owner pages ("‹ Home", "‹ Orders").
class BackPill extends StatelessWidget {
  const BackPill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(8.w, 8.h, 14.w, 8.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, size: 20.sp, color: AppColors.deepBlue),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.deepBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White section card with a thin border (detail pages).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor = AppColors.border,
    this.color = AppColors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color borderColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: AppShadows.small,
      ),
      child: child,
    );
  }
}

/// Card title row: blue icon, bold title, optional trailing widget.
class CardTitle extends StatelessWidget {
  const CardTitle({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primaryBlue),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Small uppercase grey caption ("DIMENSIONS", "TRANSACTION HISTORY").
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key, this.color = AppColors.grey});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5.sp,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

/// Selectable rounded chip used in filters and reason pickers.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
    this.icon,
    this.count,
    this.selectedFg = AppColors.primaryBlue,
    this.selectedBg = AppColors.lightBlue,
    this.selectedBorder = AppColorsExtra.infoBorder,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;
  final IconData? icon;
  final String? count;
  final Color selectedFg;
  final Color selectedBg;
  final Color selectedBorder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? selectedBorder : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8.w,
                height: 8.w,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              SizedBox(width: 6.w),
            ],
            if (icon != null) ...[
              Icon(
                icon,
                size: 15.sp,
                color: selected ? selectedFg : AppColors.grey,
              ),
              SizedBox(width: 5.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? selectedFg : AppColors.textDark,
              ),
            ),
            if (count != null) ...[
              SizedBox(width: 6.w),
              Text(
                count!,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? selectedFg : AppColors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Radio dot (blue filled check when selected).
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected, this.size = 22});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primaryBlue : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.primaryBlue : AppColors.greyLight,
          width: 1.6,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: (size * 0.65).sp, color: AppColors.white)
          : null,
    );
  }
}

/// Rounded input box with an optional label above it.
class LabeledInput extends StatelessWidget {
  const LabeledInput({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixText,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6.h),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: maxLines > 1 ? 10.h : 0,
          ),
          constraints: BoxConstraints(minHeight: 46.h),
          decoration: BoxDecoration(
            color: AppColorsExtra.panelGrey,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColorsExtra.panelBorder),
          ),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 18.sp, color: AppColors.grey),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.greyLight,
                    ),
                  ),
                ),
              ),
              if (suffixText != null)
                Text(
                  suffixText!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Every change is recorded in the audit log" footer line.
class AuditNote extends StatelessWidget {
  const AuditNote(this.text, {super.key, this.icon = Icons.shield_outlined});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.grey),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark confirmation toast ("Inventory updated: +40 units ...").
/// Shown at the bottom of the screen above everything else.
/// [info] = neutral blue "i" icon instead of the green check (for notices
/// such as "coming soon" that are not a completed action).
void showDarkToast(
  String message, {
  String trailing = 'Just now',
  bool info = false,
}) {
  final accent = info ? AppColorsExtra.infoBorder : AppColors.success;
  Get.showSnackbar(
    GetSnackBar(
      messageText: Row(
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              info ? Icons.info_outline : Icons.check,
              size: 14.sp,
              color: accent,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 11.sp,
              fontFamily: 'monospace',
              color: AppColors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      backgroundColor: AppColorsExtra.toastDark,
      borderRadius: 16.r,
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 250),
    ),
  );
}
