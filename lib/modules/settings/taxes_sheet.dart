import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/company_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import '../../app/theme/app_colors.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';

/// Edit the two tax rates (GST and PST). They are saved in the store settings
/// and every NEW order uses them. Old orders keep the rates they were made
/// with. Only the owner can save (the Firestore rules enforce it).
class TaxesController extends GetxController {
  TaxesController(this.initial);

  final CompanyInfo initial;

  /// Each rate can be 0 to 25 %, and both together at most 30 % (the
  /// Firestore rules enforce the same numbers).
  static const double maxPercent = 25;
  static const int maxTotalBp = 3000;

  final _repo = CompanyRepository();

  /// 500 -> "5", 725 -> "7.25", 750 -> "7.5".
  static String _fmt(int bp) {
    if (bp % 100 == 0) return '${bp ~/ 100}';
    var s = (bp / 100).toStringAsFixed(2);
    if (s.endsWith('0')) s = s.substring(0, s.length - 1);
    return s;
  }

  // Not disposed on purpose: the closing animation of the sheet is still
  // drawing these fields (disposing them then crashes the screen).
  late final gstController = TextEditingController(text: _fmt(initial.gstBp));
  late final pstController = TextEditingController(text: _fmt(initial.pstBp));

  final isSaving = false.obs;
  final errors = <String, String>{}.obs;
  final error = RxnString();

  /// The total of both rates, shown under the fields ("12%").
  final total = ''.obs;

  /// The rate in basis points (5 -> 500), or null when it is not valid.
  int? _bp(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > maxPercent) return null;
    final bp = (v * 100).round();
    if ((v * 100 - bp).abs() > 0.0001) return null; // more than 2 decimals
    return bp;
  }

  void _updateTotal() {
    final g = _bp(gstController.text);
    final p = _bp(pstController.text);
    total.value = (g == null || p == null) ? '—' : '${_fmt(g + p)}%';
  }

  @override
  void onInit() {
    super.onInit();
    gstController.addListener(() {
      errors.remove('gst');
      error.value = null;
      _updateTotal();
    });
    pstController.addListener(() {
      errors.remove('pst');
      error.value = null;
      _updateTotal();
    });
    _updateTotal();
  }

  Future<void> onSave() async {
    if (isSaving.value) return; // ignore double taps
    error.value = null;
    errors.clear();

    final g = _bp(gstController.text);
    final p = _bp(pstController.text);
    const msg = 'Enter a rate from 0 to 25 (at most 2 decimals).';
    if (g == null) errors['gst'] = msg;
    if (p == null) errors['pst'] = msg;
    if (g == null || p == null) return;
    if (g + p > maxTotalBp) {
      error.value = 'The two taxes together cannot be above 30%.';
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    isSaving.value = true;
    try {
      // copyWith keeps the company details, which are not edited here.
      await _repo.save(initial.copyWith(gstBp: g, pstBp: p));
      Get.back(result: true);
    } catch (e) {
      error.value = describeCustomerError(e);
    } finally {
      isSaving.value = false;
    }
  }

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Taxes. Open it with TaxesSheet.open().
/// Returns true when the rates were saved.
class TaxesSheet extends GetView<TaxesController> {
  const TaxesSheet({super.key});

  static Future<bool?> open(CompanyInfo initial) {
    // The controller is NOT deleted when the sheet closes (the closing
    // animation is still drawing it). The next open() replaces it.
    if (Get.isRegistered<TaxesController>()) {
      Get.delete<TaxesController>(force: true);
    }
    Get.put(TaxesController(initial));
    return Get.bottomSheet<bool>(
      const TaxesSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
  }

  Widget _fieldError(String key) {
    return Obx(() {
      final text = controller.errors[key];
      if (text == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(top: 6.h, left: 4.w),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      footer: Obx(
        () => PrimaryArrowButton(
          label: controller.isSaving.value ? 'Saving...' : 'Save Tax Rates',
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
                  'Taxes',
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
            'Applied to every new order. Old orders keep the rates they were '
            'made with. Only the owner can change them.',
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.35,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 16.h),
          LabeledInput(
            controller: controller.gstController,
            label: 'GST rate',
            hint: '5',
            prefixIcon: Icons.percent,
            suffixText: '%',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _fieldError('gst'),
          SizedBox(height: 12.h),
          LabeledInput(
            controller: controller.pstController,
            label: 'PST rate',
            hint: '7',
            prefixIcon: Icons.percent,
            suffixText: '%',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          _fieldError('pst'),
          SizedBox(height: 14.h),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: Text(
                    'Total tax on a sale',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  controller.total.value,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepBlue,
                  ),
                ),
              ],
            ),
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
          Text(
            'The GST and PST registration numbers are in Store profile.',
            style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
          ),
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