import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Image.asset(
                    'assets/images/logo.png',
                    width: 170.w,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
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
      case ResetStep.email:
        return 'Reset Password';
      case ResetStep.sent:
        return 'Check Your Email';
    }
  }

  String _subtitle(ResetStep step) {
    switch (step) {
      case ResetStep.email:
        return 'Enter your email and we\'ll send you a\nlink to reset your password';
      case ResetStep.sent:
        return 'If ${controller.email} is registered, we sent\na reset link. Check your inbox and spam folder.';
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
              step == ResetStep.email ? 'Back to Sign In' : 'Back',
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
      case ResetStep.email:
        return _buildEmailStep();
      case ResetStep.sent:
        return _buildSentStep();
    }
  }

  // ---------------- Step 1: email ----------------
  Widget _buildEmailStep() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel(label: 'Employee Email'),
          AppField(
            controller: controller.emailController,
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            hint: 'Enter your email',
          ),
          Obx(() {
            final error = controller.emailError.value;
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
            label: 'Send Reset Link',
            leadingIcon: Icons.send_outlined,
            onPressed: controller.onSendPressed,
          ),
        ],
      ),
    );
  }

  // ---------------- Step 2: link sent ----------------
  Widget _buildSentStep() {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 30.sp,
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Open the link in the email to choose a new\npassword, then sign in with it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.3,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 16.h),
          _buildResendInfo(),
          SizedBox(height: 20.h),
          PrimaryArrowButton(
            label: 'Back to Sign In',
            leadingIcon: Icons.login,
            onPressed: controller.onBackToSignInPressed,
          ),
        ],
      ),
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
              'Resend link in ',
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
              'Resend Link',
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
}