import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Row of code boxes (same look as the PIN screen).
/// Filled = dot, current box = blue border + cursor.
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({super.key, required this.value, this.length = 4});

  final String value;
  final int length;

  @override
  Widget build(BuildContext context) {
    final filledCount = value.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final filled = i < filledCount;
        final active = i == filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.symmetric(horizontal: 7.w),
          width: 58.w,
          height: 64.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: active ? AppColors.primaryBlue : Colors.transparent,
              width: 1.6,
            ),
            boxShadow: active
                ? [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.25),
                blurRadius: 12,
              ),
            ]
                : AppShadows.small,
          ),
          child: filled
              ? Container(
            width: 16.w,
            height: 16.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.deepBlue,
            ),
          )
              : active
              ? Container(
            width: 2,
            height: 26.h,
            color: AppColors.primaryBlue,
          )
              : null,
        );
      }),
    );
  }
}

/// Numeric keypad (same look as the PIN screen).
class NumberKeypad extends StatelessWidget {
  const NumberKeypad({
    super.key,
    required this.onNumber,
    required this.onDelete,
  });

  final ValueChanged<String> onNumber;
  final VoidCallback onDelete;

  static const Map<String, String> _letters = {
    '1': '',
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '+',
  };

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> children) => Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: 12.w),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );

    Widget digit(String n) => _KeyButton(
      title: n,
      subtitle: _letters[n] ?? '',
      onTap: () => onNumber(n),
    );

    return Column(
      children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          const SizedBox.shrink(),
          digit('0'),
          _KeyButton(
            icon: Icons.backspace_outlined,
            subtitle: 'CLEAR',
            onTap: onDelete,
          ),
        ]),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.title,
    this.icon,
    required this.subtitle,
    required this.onTap,
  });

  final String? title;
  final IconData? icon;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 58.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border.withOpacity(0.7)),
            boxShadow: AppShadows.small,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.1,
                  ),
                )
              else
                Icon(icon, size: 20.sp, color: AppColors.grey),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 8.sp,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}