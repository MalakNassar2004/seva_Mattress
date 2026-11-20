import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/customer_activity_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

class CustomerNoteController extends GetxController {
  CustomerNoteController({
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  static const int maxLength = 1000;

  final _repo = CustomerActivityRepository();

  /// Created ONCE for this sheet (see CustomerActivityRepository.newNoteId).
  late final String _noteId = _repo.newNoteId(customerId);

  // Not disposed on purpose (see the Login controller note).
  final textController = TextEditingController();
  final isSaving = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    textController.addListener(() => error.value = null);
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps

    final text = textController.text.trim();
    if (text.isEmpty) {
      error.value = 'Write the note first.';
      return;
    }
    if (text.length > maxLength) {
      error.value = 'The note is too long (max $maxLength characters).';
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    isSaving.value = true;
    try {
      await _repo.addNote(
        customerId: customerId,
        customerName: customerName,
        noteId: _noteId,
        text: text,
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

/// Bottom sheet: Log After-Sales Note. Returns true when a note was saved.
class CustomerNoteSheet extends GetView<CustomerNoteController> {
  const CustomerNoteSheet({super.key});

  static Future<bool?> open({
    required String customerId,
    required String customerName,
  }) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<CustomerNoteController>()) {
      Get.delete<CustomerNoteController>(force: true);
    }
    Get.put(CustomerNoteController(
      customerId: customerId,
      customerName: customerName,
    ));
    return Get.bottomSheet<bool>(
      const CustomerNoteSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      footer: Obx(
        () => PrimaryArrowButton(
          label: controller.isSaving.value ? 'Saving...' : 'Save Note',
          leadingIcon: Icons.edit_note,
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
                  'After-Sales Note',
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
            controller.customerName,
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
          ),
          SizedBox(height: 16.h),
          LabeledInput(
            controller: controller.textController,
            label: 'Note',
            hint: 'e.g. Gate code changed to #4820',
            maxLines: 5,
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
          SizedBox(height: 12.h),
          const AuditNote(
            'Notes cannot be edited or deleted after saving',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}