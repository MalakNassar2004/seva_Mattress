import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import 'pin_controller.dart';

class PinView extends GetView<PinController> {
  const PinView({super.key});

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
    Get.put(PinController());

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      children: [
                        SizedBox(height: 12.h),
                        _buildTopBar(),
                        SizedBox(height: 40.h),
                        _buildUserCard(),
                        SizedBox(height: 28.h),
                        Text(
                          'Security PIN Required',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepBlue,
                          ),
                        ),
                        SizedBox(height: 28.h),
                        _buildPinBoxes(),
                        SizedBox(height: 16.h),
                        _buildResendInfo(),
                        const Spacer(),
                        _buildKeypad(),
                        SizedBox(height: 28.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        WhitePill(
          onTap: controller.onChangeUserPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: 20.sp, color: AppColors.primaryBlue),
              SizedBox(width: 1.w),
              Text(
                'Change User',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          ),
        ),
        WhitePill(child: AppLogo(height: 15.h)),
      ],
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(40.r),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBlue,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              'MV',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.deepBlue,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Marcus Vance',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '•  Sales Associate',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Terminal ID: ******789',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: 'monospace',
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 18.sp, color: AppColors.deepBlue),
        ],
      ),
    );
  }

  Widget _buildPinBoxes() {
    return Obx(() {
      final length = controller.pin.value.length;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(PinController.pinLength, (i) {
          final filled = i < length;
          final active = i == length;
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
    });
  }

  Widget _buildResendInfo() {
    return Obx(() {
      final waiting = controller.secondsLeft.value > 0;
      return Column(
        children: [
          if (waiting)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: controller.secondsLeft.value /
                        PinController.resendSeconds,
                    color: AppColors.primaryBlue,
                    backgroundColor: AppColors.lightBlue,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Resend code option available in ',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.textDark),
                ),
                Text(
                  controller.timerText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: controller.onRequestOtpPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sms_outlined,
                  size: 16.sp,
                  color: waiting ? AppColors.greyLight : AppColors.primaryBlue,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Request New OTP via SMS',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: waiting ? AppColors.greyLight : AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildKeypad() {
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
      onTap: () => controller.onNumberPressed(n),
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
            onTap: controller.onDeletePressed,
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