import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LoginController());

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 25.h),
                const BrandBadge(),
                SizedBox(height: 18.h),
                Text(
                  'Terminal Sign In',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Enter your authorized associate credentials to\nunlock POS floor operations',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppColors.grey,
                  ),
                ),
                SizedBox(height: 56.h),
                _buildFormCard(),
                SizedBox(height: 60.h),
                _buildDivider('QUICK ACCESS OPTIONS'),
                SizedBox(height: 14.h),
                _buildGoogleButton(),
                SizedBox(height: 10.h),
                _buildFaceIdCard(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(
            label: 'Employee Email',
            trailing: Text(
              'Authorized Floor ID',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.grey,
              ),
            ),
          ),
          AppField(
            controller: controller.emailController,
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            suffix: Obx(
                  () => controller.hasEmail.value
                  ? GestureDetector(
                onTap: controller.clearEmail,
                child: Icon(
                  Icons.cancel_outlined,
                  size: 20.sp,
                  color: AppColors.grey,
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ),
          SizedBox(height: 15.h),
          const FieldLabel(label: 'POS PIN / Password'),
          Obx(
                () => AppField(
              controller: controller.passwordController,
              prefixIcon: Icons.lock_outline,
              obscureText: controller.obscurePassword.value,
              suffix: GestureDetector(
                onTap: controller.toggleObscure,
                child: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20.sp,
                  color: AppColors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: controller.onForgotPasswordPressed,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          PrimaryArrowButton(
            label: 'Sign In to Terminal',
            leadingIcon: Icons.badge_outlined,
            onPressed: controller.onLoginPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w500,
              color: AppColors.greyLight,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildFaceIdCard() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: controller.onFaceIdPressed,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 56.h,
          padding: EdgeInsets.only(left: 16.w, right: 32.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.small,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(child: FaceIdIcon(size: 24.w)),
              ),
              SizedBox(width: 10.w),
              Text(
                'Face ID',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Quick Auth',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: controller.onGoogleLoginPressed,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 56.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.small,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/google_logo.png',
                width: 20.w,
                height: 20.w,
                filterQuality: FilterQuality.high,
              ),
              SizedBox(width: 12.w),
              Text(
                'Continue with Google',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}