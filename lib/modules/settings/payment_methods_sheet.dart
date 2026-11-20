import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/services/payment_methods.dart';
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

/// Choose which payment methods can be used when recording a payment, taking
/// a deposit or issuing a refund. At least one must stay on. Only the owner
/// can save (the Firestore rules enforce it).
class PaymentMethodsController extends GetxController {
  PaymentMethodsController(this.initial);

  final CompanyInfo initial;

  static const Map<String, (IconData, String)> info = {
    'Card': (
      Icons.credit_card,
      'Card terminal payments. The app only records them.',
    ),
    'Cash': (Icons.payments_outlined, 'Cash at the counter or on delivery.'),
    'E-Transfer': (Icons.swap_horiz, 'Interac e-Transfer.'),
    'Financing': (
      Icons.account_balance_outlined,
      'Payments made through a financing company.',
    ),
  };

  final _repo = CompanyRepository();

  late final on = <String>{...initial.paymentMethods}.obs;
  final isSaving = false.obs;
  final error = RxnString();

  void toggle(String method, bool value) {
    error.value = null;
    if (value) {
      on.add(method);
    } else {
      on.remove(method);
    }
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps
    final list = [
      for (final m in PaymentMethodsConfig.all)
        if (on.contains(m)) m,
    ];
    if (list.isEmpty) {
      error.value = 'Keep at least one payment method on.';
      return;
    }

    isSaving.value = true;
    try {
      // copyWith keeps everything else in the store settings.
      await _repo.save(initial.copyWith(paymentMethods: list));
      Get.back(result: true);
    } catch (e) {
      error.value = describeCustomerError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Payment methods. Open it with PaymentMethodsSheet.open().
/// Returns true when the list was saved.
class PaymentMethodsSheet extends GetView<PaymentMethodsController> {
  const PaymentMethodsSheet({super.key});

  static Future<bool?> open(CompanyInfo initial) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<PaymentMethodsController>()) {
      Get.delete<PaymentMethodsController>(force: true);
    }
    Get.put(PaymentMethodsController(initial));
    return Get.bottomSheet<bool>(
      const PaymentMethodsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  Widget _row(String method) {
    final (icon, helper) = PaymentMethodsController.info[method]!;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.sp, color: AppColors.deepBlue),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  helper,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.3,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Switch.adaptive(
              value: controller.on.contains(method),
              activeTrackColor: AppColors.primaryBlue,
              onChanged: (v) => controller.toggle(method, v),
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
                  'Payment methods',
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
            'The methods that can be chosen for a deposit, a payment or a '
            'refund. Only the owner can change them.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 18.h),
          for (final m in PaymentMethodsConfig.all) _row(m),
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