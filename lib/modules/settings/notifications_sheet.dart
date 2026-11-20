import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/repositories/notification_prefs_repository.dart';
import 'package:seva_mattress/data/services/notification_types.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

/// Choose which notifications are on. Only the owner can save (the Firestore
/// rules enforce it).
class NotificationsController extends GetxController {
  NotificationsController(this.initial);

  final Set<String> initial;

  final _repo = NotificationPrefsRepository();

  late final on = <String>{...initial}.obs;
  final isSaving = false.obs;
  final error = RxnString();

  void toggle(String id, bool value) {
    error.value = null;
    if (value) {
      on.add(id);
    } else {
      on.remove(id);
    }
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps
    isSaving.value = true;
    try {
      await _repo.save({...on});
      Get.back(result: true);
    } catch (e) {
      error.value = describeCustomerError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Notifications. Open it with NotificationsSheet.open().
/// Returns true when the choice was saved.
class NotificationsSheet extends GetView<NotificationsController> {
  const NotificationsSheet({super.key});

  static Future<bool?> open(Set<String> initial) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<NotificationsController>()) {
      Get.delete<NotificationsController>(force: true);
    }
    Get.put(NotificationsController(initial));
    return Get.bottomSheet<bool>(
      const NotificationsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  Widget _heading(String title, String helper) => Padding(
    padding: EdgeInsets.only(top: 18.h, bottom: 10.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          helper,
          style: TextStyle(
            fontSize: 12.5.sp,
            height: 1.35,
            color: AppColors.grey,
          ),
        ),
      ],
    ),
  );

  Widget _row(NotificationType t) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  t.needsServer
                      ? '${t.helper} Not active yet: it needs the paid '
                          'Firebase plan and the Apple push key.'
                      : t.helper,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.3,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => Switch.adaptive(
              value: controller.on.contains(t.id),
              activeTrackColor: AppColors.primaryBlue,
              onChanged: (v) => controller.toggle(t.id, v),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Notifications',
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
            'Choose which notifications are on. It applies to every phone, '
            'and only the owner can change it.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          _heading(
            'Reminders',
            'Scheduled on each phone at 9:00 AM. A phone gets them after the '
                'app was opened on it.',
          ),
          for (final t in NotificationTypes.reminders) _row(t),
          _heading(
            'Instant alerts',
            'Sent right when it happens, even if the app is closed. They '
                'start when the server is set up.',
          ),
          for (final t in NotificationTypes.instant) _row(t),
          Obx(() {
            final err = controller.error.value;
            if (err == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 4.h),
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
          SizedBox(height: 12.h),
          const AuditNote(
            'Changes are recorded in the audit log',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}