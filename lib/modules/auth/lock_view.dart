import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import 'app_lock_controller.dart';

class LockView extends GetView<AppLockController> {
  const LockView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SoftBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 25.h),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 170.w,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const Spacer(),
                  FaceIdIcon(size: 64.w),
                  SizedBox(height: 18.h),
                  Text(
                    'App Locked',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Obx(
                    () => Text(
                      controller.message.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  PrimaryArrowButton(
                    label: 'Unlock with Face ID',
                    leadingIcon: Icons.lock_open_outlined,
                    onPressed: controller.unlock,
                  ),
                  SizedBox(height: 14.h),
                  GestureDetector(
                    onTap: controller.signOutAndExit,
                    child: Text(
                      'Sign out',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}