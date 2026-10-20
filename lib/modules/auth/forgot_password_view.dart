import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/pin_widgets.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ForgotPasswordController());

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Obx(() {
              final step = controller.step.value;
              return Column(
                children: [
                  SizedBox(height: 12.h),
                  _buildBackPill(step),
                  SizedBox(height: 25.h),
                  const BrandBadge(),
                  SizedBox(height: 18.h),
                  Text(
                    _title(step),
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _subtitle(step),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.3,
                      color: AppColors.grey,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey(step),
                      child: _buildStep(step),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  String _title(ResetStep step) {
    switch (step) {
      case ResetStep.contact:
        return 'Reset Password';
      case ResetStep.otp:
        return 'Verify Code';
      case ResetStep.newPassword:
        return 'Create New Password';
    }
  }

  String _subtitle(ResetStep step) {
    switch (step) {
      case ResetStep.contact:
        return 'Choose how you want to recover\nyour account';
      case ResetStep.otp:
        final where = controller.isPhone ? 'phone number' : 'email';
        return 'Enter the 4-digit code we sent to your $where\n${controller.contactController.text.trim()}';
      case ResetStep.newPassword:
        return 'Your new password must be at least\n${ForgotPasswordController.minPasswordLength} characters long';
    }
  }

  Widget _buildBackPill(ResetStep step) {
    return Align(
      alignment: Alignment.centerLeft,
      child: WhitePill(
        onTap: controller.onBackPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, size: 22.sp, color: AppColors.primaryBlue),
            SizedBox(width: 2.w),
            Text(
              step == ResetStep.contact ? 'Back to Sign In' : 'Back',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.deepBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ResetStep step) {
    switch (step) {
      case ResetStep.contact:
        return _buildContactStep();
      case ResetStep.otp:
        return _buildOtpStep();
      case ResetStep.newPassword:
        return _buildNewPasswordStep();
    }
  }

  // ---------------- Step 1 ----------------
  Widget _buildContactStep() {
    final isPhone = controller.isPhone;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MethodTile(
            title: 'Phone Number',
            icon: Icon(Icons.phone_outlined, size: 22.sp, color: AppColors.primaryBlue),
            selected: isPhone,
            onTap: () => controller.selectMethod(ResetMethod.phone),
          ),
          SizedBox(height: 12.h),
          _MethodTile(
            title: 'Google Email',
            icon: Image.asset(
              'assets/images/google_logo.png',
              width: 22.w,
              height: 22.w,
              filterQuality: FilterQuality.high,
            ),
            selected: !isPhone,
            onTap: () => controller.selectMethod(ResetMethod.google),
          ),
          SizedBox(height: 20.h),
          FieldLabel(label: isPhone ? 'Phone Number' : 'Google Email'),
          AppField(
            controller: controller.contactController,
            prefixIcon: isPhone ? Icons.phone_outlined : Icons.mail_outline,
            keyboardType:
            isPhone ? TextInputType.phone : TextInputType.emailAddress,
            hint: isPhone ? 'Enter your phone number' : 'Enter your Google email',
          ),
          Obx(() {
            final error = controller.contactError.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.danger,
                ),
              ),
            );
          }),
          SizedBox(height: 20.h),
          PrimaryArrowButton(
            label: 'Send Code',
            leadingIcon: Icons.send_outlined,
            onPressed: controller.onSendCodePressed,
          ),
        ],
      ),
    );
  }

  // ---------------- Step 2 ----------------
  Widget _buildOtpStep() {
    return Column(
      children: [
        Obx(() => OtpBoxes(
          value: controller.otp.value,
          length: ForgotPasswordController.otpLength,
        )),
        SizedBox(height: 16.h),
        _buildResendInfo(),
        SizedBox(height: 28.h),
        NumberKeypad(
          onNumber: controller.onNumberPressed,
          onDelete: controller.onDeletePressed,
        ),
        SizedBox(height: 8.h),
        PrimaryArrowButton(
          label: 'Verify Code',
          leadingIcon: Icons.verified_user_outlined,
          onPressed: controller.onVerifyPressed,
        ),
      ],
    );
  }

  Widget _buildResendInfo() {
    return Obx(() {
      final waiting = controller.secondsLeft.value > 0;
      if (waiting) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: controller.secondsLeft.value /
                    ForgotPasswordController.resendSeconds,
                color: AppColors.primaryBlue,
                backgroundColor: AppColors.lightBlue,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Resend code in ',
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
        );
      }
      return GestureDetector(
        onTap: controller.onResendPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 16.sp, color: AppColors.primaryBlue),
            SizedBox(width: 6.w),
            Text(
              'Resend Code',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ---------------- Step 3 ----------------
  Widget _buildNewPasswordStep() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel(label: 'New Password'),
          Obx(
                () => AppField(
              controller: controller.newPasswordController,
              prefixIcon: Icons.lock_outline,
              obscureText: controller.obscureNew.value,
              suffix: GestureDetector(
                onTap: controller.toggleObscureNew,
                child: Icon(
                  controller.obscureNew.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20.sp,
                  color: AppColors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Obx(
                () => _Rule(
              text: 'At least ${ForgotPasswordController.minPasswordLength} characters',
              ok: controller.hasMinLength,
            ),
          ),
          SizedBox(height: 15.h),
          const FieldLabel(label: 'Confirm Password'),
          Obx(
                () => AppField(
              controller: controller.confirmPasswordController,
              prefixIcon: Icons.lock_outline,
              obscureText: controller.obscureConfirm.value,
              suffix: GestureDetector(
                onTap: controller.toggleObscureConfirm,
                child: Icon(
                  controller.obscureConfirm.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20.sp,
                  color: AppColors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Obx(
                () => _Rule(
              text: 'Passwords match',
              ok: controller.passwordsMatch,
            ),
          ),
          SizedBox(height: 20.h),
          PrimaryArrowButton(
            label: 'Reset Password',
            leadingIcon: Icons.lock_reset,
            onPressed: controller.onResetPressed,
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final Widget icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightBlue.withOpacity(0.45) : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.white : AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: icon,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22.sp,
              color: selected ? AppColors.primaryBlue : AppColors.greyLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text, required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16.sp,
          color: ok ? AppColors.success : AppColors.greyLight,
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: ok ? AppColors.success : AppColors.grey,
          ),
        ),
      ],
    );
  }
}