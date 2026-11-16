import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import 'adjust_stock_controller.dart';

/// Bottom sheet: Adjust Stock. Open it with
/// Get.bottomSheet(const AdjustStockSheet(), isScrollControlled: true, ...)
/// Bottom sheets are not routes, so the controller is created here with
/// Get.put instead of a binding.
class AdjustStockSheet extends GetView<AdjustStockController> {
  const AdjustStockSheet({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AdjustStockController());
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.92,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 10.h, bottom: 10.h),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 14.h),
                    _buildAuditBanner(),
                    SizedBox(height: 14.h),
                    _buildProductCard(),
                    SizedBox(height: 18.h),
                    _buildModeSection(),
                    SizedBox(height: 18.h),
                    _buildLocationSection(),
                    SizedBox(height: 18.h),
                    _buildReasonSection(),
                    SizedBox(height: 14.h),
                    _buildNoteSection(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Adjust Stock',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'CAD',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'SKU: ',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                    TextSpan(
                      text: AdjustStockController.sku,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextSpan(
                      text: ' · Surrey Flagship',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: controller.onClosePressed,
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 18.sp, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditBanner() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.infoBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColorsExtra.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user, size: 20.sp, color: AppColors.primaryBlue),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'This adjustment is recorded in the immutable audit log with your owner signature.',
              style: TextStyle(
                fontSize: 12.sp,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColors.deepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bed_outlined,
                    size: 24.sp, color: AppColors.primaryBlue),
                Text(
                  'PLUSH 6.5',
                  style: TextStyle(
                    fontSize: 7.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AdjustStockController.productName,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${AdjustStockController.baseUnits} units on hand',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  5 Whse, 3 Floor',
                        style:
                            TextStyle(fontSize: 11.sp, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Cost Basis: ',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${formatCad(AdjustStockController.cost)} CAD / unit',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Mode + quantity ----------------
  Widget _buildModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adjustment Mode',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Base: ${AdjustStockController.baseUnits} on hand',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.segmentBg,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                _modeButton(
                  AdjustMode.setQuantity,
                  Icons.pin_outlined,
                  'Set New Quantity',
                ),
                _modeButton(
                  AdjustMode.relative,
                  Icons.swap_vert,
                  'Relative Change (±)',
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        _buildCounter(),
      ],
    );
  }

  Widget _modeButton(AdjustMode m, IconData icon, String label) {
    final selected = controller.mode.value == m;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setMode(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17.sp,
                  color: selected ? AppColors.white : AppColors.grey),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.white : AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Obx(() {
        final d = controller.delta;
        final isRelative = controller.mode.value == AdjustMode.relative;
        final Color fg = d > 0
            ? AppColors.success
            : d < 0
                ? AppColors.danger
                : AppColors.grey;
        final Color bg = d > 0
            ? AppColors.successBg
            : d < 0
                ? AppColors.dangerBg
                : AppColorsExtra.panelGrey;
        final String chip = d == 0
            ? 'No change'
            : '${d > 0 ? '↑ +' : '↓ −'}${d.abs()} unit${d.abs() == 1 ? '' : 's'}'
                '  |  ${d > 0 ? '+' : '−'} ${formatCad(controller.valueDelta.abs())} CAD inventory value';

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _roundButton(
                  icon: Icons.remove,
                  bg: const Color(0xFFEDEFF3),
                  fg: AppColors.textDark,
                  onTap: controller.decrement,
                ),
                Column(
                  children: [
                    Text(
                      isRelative && controller.value.value > 0
                          ? '+${controller.value.value}'
                          : '${controller.value.value}',
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      isRelative
                          ? 'Change (total ${controller.total})'
                          : 'Total Units',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                  ],
                ),
                _roundButton(
                  icon: Icons.add,
                  bg: AppColors.lightBlue,
                  fg: AppColors.primaryBlue,
                  border: AppColors.primaryBlue,
                  onTap: controller.increment,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: fg.withValues(alpha: 0.25)),
              ),
              child: Text(
                chip,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    Color? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border == null ? null : Border.all(color: border, width: 1.5),
        ),
        child: Icon(icon, size: 24.sp, color: fg),
      ),
    );
  }

  // ---------------- Sub-location ----------------
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Sub-Location',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Row(
            children: List.generate(AdjustStockController.locations.length, (i) {
              final loc = AdjustStockController.locations[i];
              final selected = controller.location.value == i;
              final units = controller.newUnitsFor(i);
              final changed = selected && controller.delta != 0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i == AdjustStockController.locations.length - 1
                          ? 0
                          : 10.w),
                  child: GestureDetector(
                    onTap: () => controller.selectLocation(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColorsExtra.infoBg
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            loc.$3,
                            size: 20.sp,
                            color: selected
                                ? AppColors.primaryBlue
                                : (i == 2
                                    ? AppColors.warning
                                    : AppColors.deepBlue),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  loc.$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: selected
                                        ? AppColors.deepBlue
                                        : AppColors.textDark,
                                  ),
                                ),
                              ),
                              if (selected) ...[
                                SizedBox(width: 3.w),
                                Icon(Icons.check,
                                    size: 14.sp, color: AppColors.primaryBlue),
                              ],
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            changed
                                ? '${loc.$2} → $units units'
                                : '$units units',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.primaryBlue
                                  : AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ---------------- Reason + note ----------------
  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Reason for adjustment',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Mandatory audit field',
              style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Obx(
          () => Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: controller.reasonError.value
                    ? AppColors.danger
                    : AppColors.border,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.reason.value,
                icon: Icon(Icons.unfold_more,
                    size: 20.sp, color: AppColors.grey),
                hint: Text(
                  'Select a reason',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.greyLight),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                borderRadius: BorderRadius.circular(14.r),
                dropdownColor: AppColors.white,
                items: AdjustStockController.reasons
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: controller.selectReason,
              ),
            ),
          ),
        ),
        Obx(
          () => controller.reasonError.value
              ? Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    'A reason is required for the audit log',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.danger,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Audit note / PO Reference',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              TextSpan(
                text: ' (Optional)',
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller.noteController,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Add a note or PO reference',
              hintStyle: TextStyle(fontSize: 13.sp, color: AppColors.greyLight),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Footer ----------------
  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryArrowButton(
              label: 'Confirm Adjustment',
              leadingIcon: Icons.check_circle_outline,
              onPressed: controller.onConfirmPressed,
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 13.sp, color: AppColors.grey),
                SizedBox(width: 5.w),
                Text(
                  'Recorded in the audit log · Owner ID #OWN-001',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
