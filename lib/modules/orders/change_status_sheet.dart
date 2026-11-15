import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'order_models.dart';

/// Result of the Change Status sheet.
class StatusChange {
  const StatusChange(this.status, this.note, this.notifyCustomer);

  final OrderStatus status;
  final String note;
  final bool notifyCustomer;
}

class ChangeStatusController extends GetxController {
  ChangeStatusController(this.current);

  final OrderStatus current;
  late final selected = current.obs;
  final notifyCustomer = true.obs;
  final noteController = TextEditingController();

  void select(OrderStatus s) => selected.value = s;
  void toggleNotify(bool v) => notifyCustomer.value = v;

  void onConfirm() => Get.back(
        result: StatusChange(
          selected.value,
          noteController.text.trim(),
          notifyCustomer.value,
        ),
      );

  void onClosePressed() => Get.back();

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}

/// Bottom sheet: Change Status. Open it with ChangeStatusSheet.open().
/// Bottom sheets are not routes, so the controller is created by open().
class ChangeStatusSheet extends GetView<ChangeStatusController> {
  const ChangeStatusSheet({super.key});

  static Future<StatusChange?> open(OrderStatus current) async {
    Get.put(ChangeStatusController(current));
    final result = await Get.bottomSheet<StatusChange>(
      const ChangeStatusSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    Get.delete<ChangeStatusController>();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      footer: PrimaryArrowButton(
        label: 'Update Status',
        leadingIcon: Icons.published_with_changes,
        onPressed: controller.onConfirm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Change Status',
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
            'Currently: ${controller.current.label}',
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
          ),
          SizedBox(height: 16.h),
          Obx(
            () => Column(
              children: OrderStatus.values
                  .map((s) => _option(s, controller.selected.value == s))
                  .toList(),
            ),
          ),
          SizedBox(height: 6.h),
          LabeledInput(
            controller: controller.noteController,
            label: 'Note (optional)',
            hint: 'e.g. Foam delayed by supplier, new ETA Oct 28',
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          Obx(
            () => Row(
              children: [
                Icon(Icons.sms_outlined, size: 18.sp, color: AppColors.grey),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Notify customer by SMS & email',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: controller.notifyCustomer.value,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: controller.toggleNotify,
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          const AuditNote('Status changes are recorded in the audit log',
              icon: Icons.lock_outline),
        ],
      ),
    );
  }

  Widget _option(OrderStatus s, bool selected) {
    final isCurrent = s == controller.current;
    return GestureDetector(
      onTap: () => controller.select(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? AppColorsExtra.infoBg : AppColors.white,
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
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: s.border),
              ),
              child: Icon(s.sheetIcon, size: 20.sp, color: s.fg),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (isCurrent) ...[
                        SizedBox(width: 6.w),
                        Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    s.description,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}
