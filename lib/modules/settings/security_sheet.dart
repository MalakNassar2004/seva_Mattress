import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/services/app_lock_settings.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

/// Security settings: how long a phone can be away before Face ID is asked
/// again, and whether an SMS code is asked at sign-in. Only the owner can save
/// (the Firestore rules enforce it).
class SecurityController extends GetxController {
  SecurityController(this.initial);

  final CompanyInfo initial;

  final _repo = CompanyRepository();

  late final selected = initial.lockMinutes.obs;

  /// The SMS code can only be turned on when the real sending exists.
  late final requireSms =
      (initial.requireSms && AppLockSettings.smsAvailable).obs;

  final isSaving = false.obs;
  final error = RxnString();

  void select(int minutes) {
    selected.value = minutes;
    error.value = null;
  }

  void toggleSms(bool v) {
    if (!AppLockSettings.smsAvailable) return;
    requireSms.value = v;
    error.value = null;
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps
    isSaving.value = true;
    try {
      // copyWith keeps everything else in the store settings.
      await _repo.save(
        initial.copyWith(
          lockMinutes: selected.value,
          requireSms: requireSms.value,
        ),
      );
      Get.back(result: true);
    } catch (e) {
      error.value = describeCustomerError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Security. Open it with SecuritySheet.open().
/// Returns true when the settings were saved.
class SecuritySheet extends GetView<SecurityController> {
  const SecuritySheet({super.key});

  static Future<bool?> open(CompanyInfo initial) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<SecurityController>()) {
      Get.delete<SecurityController>(force: true);
    }
    Get.put(SecurityController(initial));
    return Get.bottomSheet<bool>(
      const SecuritySheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  @override
  Widget build(BuildContext context) {
    const smsReady = AppLockSettings.smsAvailable;
    return SheetFrame(
      footer: Obx(
        () => PrimaryArrowButton(
          label: controller.isSaving.value ? 'Saving...' : 'Save',
          leadingIcon: Icons.check,
          onPressed: controller.onSave,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SheetCloseButton(onTap: controller.onClosePressed),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'These settings apply to every phone. Only the owner can change '
            'them.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            'Face ID lock',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'The app locks with Face ID when it goes to the background. '
            'Choose how long a phone can be away before Face ID is asked '
            'again.',
            style: TextStyle(
              fontSize: 12.5.sp,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 10.h),
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final m in AppLockSettings.options)
                  ChoicePill(
                    label: AppLockSettings.label(m),
                    selected: controller.selected.value == m,
                    onTap: () => controller.select(m),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'After 3 wrong Face ID attempts the app signs the employee out.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
          ),
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMS code at sign-in',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      smsReady
                          ? 'After the password, the employee enters a code '
                              'sent by SMS.'
                          : 'Not available yet. It needs the paid Firebase '
                              'plan (Blaze) and the SMS setup. Until then '
                              'employees sign in with email and password (or '
                              'Google), then Face ID.',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        height: 1.35,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Obx(
                () => Switch.adaptive(
                  value: controller.requireSms.value,
                  activeTrackColor: AppColors.primaryBlue,
                  // null = switched off and greyed out.
                  onChanged: smsReady ? controller.toggleSms : null,
                ),
              ),
            ],
          ),
          Obx(() {
            final err = controller.error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: Text(
                err,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            );
          }),
          SizedBox(height: 14.h),
          const AuditNote(
            'Changes are recorded in the audit log',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}