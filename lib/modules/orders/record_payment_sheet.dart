import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'order_models.dart';
import 'package:seva_mattress/data/services/payment_methods.dart';

class RecordPaymentController extends GetxController {
  RecordPaymentController(this.balance);

  final double balance;

   static const List<(String, IconData)> _all = [
    ('Card', Icons.credit_card),
    ('Cash', Icons.payments_outlined),
    ('E-Transfer', Icons.swap_horiz),
    ('Financing', Icons.account_balance_outlined),
  ];

  /// Only the methods the owner turned on in Settings > Payment methods.
  static List<(String, IconData)> get methods => [
        for (final m in _all)
          if (PaymentMethodsConfig.enabled.contains(m.$1)) m,
      ];

  /// Quick amount presets. 0 = full balance, 1 = half, 2 = custom.
  static const List<String> presets = ['Full balance', '50%', 'Custom'];

  final methodIndex = 0.obs;
  final presetIndex = 0.obs;
  final amount = 0.0.obs;
  final error = RxnString();

  /// When the next payment is due. Needed only while a balance is left.
  final nextDate = Rxn<DateTime>();

  // Not disposed on purpose: the closing animation of the sheet is still
  // drawing these fields (disposing them then crashes the screen).
  late final amountController =
      TextEditingController(text: balance.toStringAsFixed(2));
  final referenceController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    amount.value = balance;
  }

  void selectMethod(int i) => methodIndex.value = i;

  void selectPreset(int i) {
    presetIndex.value = i;
    if (i == 2) return;
    final v = i == 0 ? balance : balance / 2;
    amountController.text = v.toStringAsFixed(2);
    onAmountChanged(amountController.text);
  }

  void onAmountChanged(String v) {
    amount.value = double.tryParse(v.replaceAll(',', '')) ?? 0;
    error.value = null;
  }

  String get kind {
    if (amount.value >= balance - 0.004) return 'Final balance';
    return 'Partial payment';
  }

  /// True while a balance is left after this payment.
  bool get partial => amount.value > 0 && amount.value < balance - 0.004;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> pickNextDate() async {
    final today = _today;
    var initial = nextDate.value ?? today.add(const Duration(days: 14));
    if (initial.isBefore(today)) initial = today;
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    nextDate.value = DateTime(picked.year, picked.month, picked.day);
    error.value = null;
  }

  void onConfirm() {
    final v = amount.value;
    if (v <= 0) {
      error.value = 'Enter an amount above \$0.00';
      return;
    }
    if (v > balance + 0.004) {
      error.value = 'Amount is more than the balance owing';
      return;
    }
    if (partial) {
      final d = nextDate.value;
      if (d == null) {
        error.value = 'Choose the date of the next payment';
        return;
      }
      if (d.isBefore(_today)) {
        error.value = 'The next payment date cannot be in the past';
        return;
      }
    }
    final m = methods[methodIndex.value];
    final ref = referenceController.text.trim();
    Get.back(
      result: PaymentRecord(
        method: ref.isEmpty ? m.$1 : '${m.$1} · $ref',
        dateLabel: 'Today · just now',
        kind: kind,
        amount: v,
        icon: m.$2,
        statusLabel: m.$1 == 'Card' ? 'Authorized' : 'Recorded',
        nextDate: partial ? nextDate.value : null,
      ),
    );
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Record Payment. Open it with RecordPaymentSheet.open().
class RecordPaymentSheet extends GetView<RecordPaymentController> {
  const RecordPaymentSheet({super.key});

  static Future<PaymentRecord?> open({required double balance}) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<RecordPaymentController>()) {
      Get.delete<RecordPaymentController>(force: true);
    }
    Get.put(RecordPaymentController(balance));
    return Get.bottomSheet<PaymentRecord>(
      const RecordPaymentSheet(),
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
          label: 'Record ${formatCad(controller.amount.value)}',
          leadingIcon: Icons.add_card,
          onPressed: controller.onConfirm,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Record Payment',
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
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.amberSoft,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColorsExtra.amberBorder),
            ),
            child: Row(
              children: [
                const Caption('Balance owing',
                    color: AppColorsExtra.amberText),
                const Spacer(),
                Text(
                  '${formatCad(controller.balance)} CAD',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColorsExtra.amberText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          _label('Amount'),
          Obx(
            () => Wrap(
              spacing: 8.w,
              children: List.generate(
                RecordPaymentController.presets.length,
                (i) => ChoicePill(
                  label: RecordPaymentController.presets[i],
                  selected: controller.presetIndex.value == i,
                  onTap: () => controller.selectPreset(i),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          LabeledInput(
            controller: controller.amountController,
            prefixIcon: Icons.attach_money,
            suffixText: 'CAD',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) {
              controller.presetIndex.value = 2;
              controller.onAmountChanged(v);
            },
          ),
          Obx(() {
            final err = controller.error.value;
            return Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                err ?? 'Recorded as: ${controller.kind}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: err == null ? AppColors.grey : AppColors.danger,
                ),
              ),
            );
          }),
          // A balance is left: when is the next payment due?
          Obx(() {
            if (!controller.partial) return const SizedBox.shrink();
            final d = controller.nextDate.value;
            return Padding(
              padding: EdgeInsets.only(top: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Next payment date'),
                  GestureDetector(
                    onTap: controller.pickNextDate,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 13.h),
                      decoration: BoxDecoration(
                        color: AppColorsExtra.panelGrey,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColorsExtra.panelBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 17.sp, color: AppColors.primaryBlue),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              d == null
                                  ? 'Choose when the next payment is due'
                                  : fmtOrderDate(d),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: d == null
                                    ? FontWeight.w400
                                    : FontWeight.w700,
                                color: d == null
                                    ? AppColors.grey
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 18.h),
          _label('Payment method'),
          Obx(
            () => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10.h,
              crossAxisSpacing: 10.w,
              childAspectRatio: 3.2,
              children: List.generate(RecordPaymentController.methods.length,
                  (i) {
                final m = RecordPaymentController.methods[i];
                final sel = controller.methodIndex.value == i;
                return GestureDetector(
                  onTap: () => controller.selectMethod(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: sel ? AppColorsExtra.infoBg : AppColors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: sel ? AppColors.primaryBlue : AppColors.border,
                        width: sel ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(m.$2,
                            size: 20.sp,
                            color: sel ? AppColors.primaryBlue : AppColors.grey),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            m.$1,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? AppColors.primaryBlue
                                  : AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 16.h),
          LabeledInput(
            controller: controller.referenceController,
            label: 'Reference (optional)',
            hint: 'Last 4 digits, e-transfer ID, financing #',
          ),
          SizedBox(height: 14.h),
          const AuditNote('Payments are PCI-DSS encrypted and audit logged',
              icon: Icons.verified_user_outlined),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      );
}