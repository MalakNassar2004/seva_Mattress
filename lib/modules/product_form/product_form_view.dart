import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_widgets.dart';
import 'product_form_controller.dart';

/// Add / Edit product. Same design for both:
/// isEdit = true  -> prefilled (Edit Product)
/// isEdit = false -> empty (Add Product)
class ProductFormView extends GetView<ProductFormController> {
  const ProductFormView({super.key, this.isEdit = true});

  final bool isEdit;

  static const Color _labelColor = Color(0xFF374151);
  static const Color _panelBg = Color(0xFFF6F8FB);
  static const Color _panelBorder = Color(0xFFE3E8F0);

  @override
  Widget build(BuildContext context) {
    Get.put(ProductFormController(isEdit: isEdit));

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
                  child: Column(
                    children: [
                      _buildBasicInfo(),
                      SizedBox(height: 16.h),
                      _buildPhotos(),
                      SizedBox(height: 16.h),
                      _buildSizesPricing(),
                      SizedBox(height: 16.h),
                      _buildCustomSize(),
                      SizedBox(height: 16.h),
                      _buildVisibility(),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.55),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WhitePill(
                onTap: controller.onBackPressed,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left,
                        size: 22.sp, color: AppColors.primaryBlue),
                    SizedBox(width: 2.w),
                    Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFC3D4F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 14.sp, color: AppColors.deepBlue),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'Surrey Catalogue · Owner',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: controller.onHelpPressed,
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.help_outline,
                      size: 20.sp, color: AppColors.grey),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Text(
                isEdit ? 'Edit Product' : 'Add Product',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Obx(() {
                final active = controller.isActive.value;
                final fg = active ? AppColors.success : AppColors.grey;
                final bg =
                    active ? AppColors.successBg : const Color(0xFFEDEFF3);
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: fg.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration:
                            BoxDecoration(color: fg, shape: BoxShape.circle),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        active ? 'Active in POS' : 'Hidden',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'CAD Currency · Surrey Flagship POS',
            style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------- Basic Info ----------------
  Widget _buildBasicInfo() {
    return _SectionCard(
      icon: Icons.info_outline,
      title: 'Basic Info',
      showDivider: true,
      trailing: Text(
        'Product Code ${controller.productCode}',
        style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Product Name'),
          _Input(
            controller: controller.nameController,
            hint: 'Enter product name',
          ),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Category'),
                    Obx(
                      () => _Dropdown(
                        icon: Icons.bed_outlined,
                        hint: 'Select',
                        value: controller.category.value,
                        options: ProductFormController.categories,
                        onChanged: (v) => controller.category.value = v,
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
                    _label('Model Number'),
                    _Input(
                      controller: controller.modelController,
                      hint: 'e.g. SV-HYB-2024',
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _label('Description'),
          _Input(
            controller: controller.descriptionController,
            hint: 'Describe the product',
            maxLines: 3,
            height: 92.h,
          ),
        ],
      ),
    );
  }

  // ---------------- Photos ----------------
  Widget _buildPhotos() {
    return _SectionCard(
      icon: Icons.image_outlined,
      title: 'Photos',
      trailing: Obx(
        () => Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '${controller.photoCount.value} of ${ProductFormController.maxPhotos} Uploaded',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.deepBlue,
            ),
          ),
        ),
      ),
      child: Obx(() {
        final count = controller.photoCount.value;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                _PhotoTile(
                  index: i,
                  onRemove: controller.removePhoto,
                ),
                SizedBox(width: 10.w),
              ],
              if (count < ProductFormController.maxPhotos)
                _AddPhotoTile(onTap: controller.addPhoto),
            ],
          ),
        );
      }),
    );
  }

  // ---------------- Sizes & Pricing ----------------
  Widget _buildSizesPricing() {
    return _SectionCard(
      icon: Icons.bed_outlined,
      title: 'Sizes & Pricing',
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          '${ProductFormController.sizes.length} Variants',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.success,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Size to Edit',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(
              () => Row(
                children: ProductFormController.sizes.entries.map((e) {
                  final selected = controller.selectedSize.value == e.key;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: () => controller.selectSize(e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 9.h),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryBlue
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) ...[
                              Icon(Icons.check,
                                  size: 15.sp, color: AppColors.white),
                              SizedBox(width: 4.w),
                            ],
                            Text(
                              selected ? '${e.key} ${e.value}' : e.key,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('SKU (Stock Keeping Unit)'),
                _Input(
                  controller: controller.skuController,
                  hint: 'e.g. MAT-SEV-HYB-QN',
                  mono: true,
                  suffix: Icon(Icons.qr_code_scanner,
                      size: 20.sp, color: AppColors.grey),
                ),
                SizedBox(height: 14.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Retail Price (CAD)'),
                          _MoneyInput(controller: controller.retailController),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cost Price',
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: _labelColor,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline,
                                          size: 9.sp,
                                          color: AppColors.deepBlue),
                                      SizedBox(width: 2.w),
                                      Text(
                                        'Owner',
                                        style: TextStyle(
                                          fontSize: 9.5.sp,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.deepBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _MoneyInput(
                            controller: controller.costController,
                            owner: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildMarginChip(),
                SizedBox(height: 14.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Warehouse Stock (Surrey Flagship)',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: _labelColor,
                      ),
                    ),
                    Obx(() {
                      final units = controller.stockUnits.value;
                      if (units == null) return const SizedBox.shrink();
                      final ok = units > 0;
                      return Text(
                        ok ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: ok ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(height: 6.h),
                _buildStockField(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarginChip() {
    return Obx(() {
      final margin = controller.marginPercent.value;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFBFE5CD)),
        ),
        child: Row(
          children: [
            Icon(Icons.trending_up, size: 18.sp, color: AppColors.success),
            SizedBox(width: 6.w),
            Text(
              margin != null
                  ? 'Margin ${margin.toStringAsFixed(1)}%'
                  : 'Margin —',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
            const Spacer(),
            Text(
              controller.profitText,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStockField() {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 24.w, maxWidth: 80.w),
            child: IntrinsicWidth(
              child: TextField(
                controller: controller.stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle:
                      TextStyle(fontSize: 15.sp, color: AppColors.greyLight),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            'units',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Text(
            'Available',
            style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------- Custom-Size Settings ----------------
  Widget _buildCustomSize() {
    return _SectionCard(
      icon: Icons.tune,
      title: 'Custom-Size Settings',
      trailing: Obx(
        () => _AppSwitch(
          value: controller.customSizeEnabled.value,
          onChanged: (v) => controller.customSizeEnabled.value = v,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allow customers to order custom RV, antique bed, or boat '
            'mattress dimensions tailored by Surrey factory.',
            style: TextStyle(
              fontSize: 12.5.sp,
              height: 1.4,
              color: AppColors.grey,
            ),
          ),
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: controller.customSizeEnabled.value
                  ? Padding(
                      padding: EdgeInsets.only(top: 14.h),
                      child: _buildCustomPanel(),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomPanel() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _panelLabel('Min / Max Dimensional Boundaries'),
          _Input(
            controller: controller.dimensionsController,
            hint: 'Min: 28" × 50" — Max: 84" × 96"',
          ),
          SizedBox(height: 14.h),
          _panelLabel('Selectable Thicknesses'),
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: ProductFormController.thicknessOptions.map((t) {
                final selected = controller.thicknesses.contains(t);
                return GestureDetector(
                  onTap: () => controller.toggleThickness(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBlue
                          : AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.white : AppColors.deepBlue,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 14.h),
          _panelLabel('Allowed Cut Formats'),
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final entry in const [
                  ('Square (90°)', Icons.crop_square),
                  ('Chamfer / Corner Cut', Icons.architecture),
                  ('Radius Rounded', Icons.rounded_corner),
                ])
                  _cutChip(
                    entry.$1,
                    entry.$2,
                    controller.cuts.contains(entry.$1),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          _panelLabel('Custom Pricing Formula'),
          Obx(
            () => _Dropdown(
              icon: Icons.calculate_outlined,
              hint: 'Select formula',
              value: controller.pricingFormula.value,
              options: ProductFormController.pricingFormulas,
              onChanged: (v) => controller.pricingFormula.value = v,
              bold: true,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manufacturing Notes Required',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Associate must attach blueprint sketches',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              Obx(
                () => _AppSwitch(
                  value: controller.notesRequired.value,
                  onChanged: (v) => controller.notesRequired.value = v,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cutChip(String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => controller.toggleCut(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : const Color(0xFFEFF2F7),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15.sp,
              color: selected ? AppColors.deepBlue : AppColors.greyLight,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.textDark : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Visibility & Audit ----------------
  Widget _buildVisibility() {
    return _SectionCard(
      icon: Icons.verified_user,
      title: 'Visibility & Audit',
      trailing: Text(
        'Surrey Log v4.2',
        style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
      ),
      child: Column(
        children: [
          Obx(
            () => Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _segment(
                    label: 'Active on POS',
                    icon: Icons.visibility_outlined,
                    selected: controller.isActive.value,
                    onTap: () => controller.isActive.value = true,
                  ),
                  _segment(
                    label: 'Hidden / Archive',
                    icon: Icons.visibility_off_outlined,
                    selected: !controller.isActive.value,
                    onTap: () => controller.isActive.value = false,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 20.sp, color: AppColors.deepBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Any cost price or inventory updates are recorded in the '
                    'owner audit log with timestamp & Surrey associate ID.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.4,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11.r),
            boxShadow: selected ? AppShadows.small : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17.sp,
                color: selected ? AppColors.primaryBlue : AppColors.greyLight,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? AppColors.primaryBlue : AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Bottom bar ----------------
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 62.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(18.r),
              child: InkWell(
                onTap: controller.onSavePressed,
                borderRadius: BorderRadius.circular(18.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Save Product',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Syncing Surrey Floor Catalogue',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34.w,
                        height: 34.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(0.2),
                        ),
                        child: Icon(Icons.arrow_forward,
                            size: 18.sp, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: controller.onDiscardPressed,
            child: Text(
              'Discard changes',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- helpers ----------------
  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: 6.h),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w500,
            color: _labelColor,
          ),
        ),
      );

  Widget _panelLabel(String text) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: _labelColor,
          ),
        ),
      );

  static BoxDecoration _fieldDecoration({Color? color, Color? border}) =>
      BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border ?? AppColors.border),
      );
}

// =====================================================================
// Private building blocks
// =====================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: AppColors.primaryBlue),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          if (showDivider) ...[
            SizedBox(height: 12.h),
            const Divider(),
          ],
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ProductFormView._panelBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: ProductFormView._panelBorder),
      ),
      child: child,
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.height,
    this.mono = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final double? height;
  final bool mono;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 48.h,
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: maxLines > 1 ? 10.h : 0,
      ),
      alignment: maxLines > 1 ? Alignment.topLeft : Alignment.center,
      decoration: ProductFormView._fieldDecoration(),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: mono ? 12.5.sp : 14.sp,
                height: maxLines > 1 ? 1.4 : null,
                fontFamily: mono ? 'monospace' : null,
                fontWeight: mono ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    TextStyle(fontSize: 13.sp, color: AppColors.greyLight),
              ),
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

class _MoneyInput extends StatelessWidget {
  const _MoneyInput({required this.controller, this.owner = false});

  final TextEditingController controller;
  final bool owner;

  @override
  Widget build(BuildContext context) {
    final color = owner ? AppColors.primaryBlue : AppColors.textDark;
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: ProductFormView._fieldDecoration(
        color: owner ? const Color(0xFFEAF0FB) : AppColors.white,
        border: owner ? const Color(0xFFC9D8F2) : AppColors.border,
      ),
      child: Row(
        children: [
          Text(
            '\$',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle:
                    TextStyle(fontSize: 15.sp, color: AppColors.greyLight),
              ),
            ),
          ),
          Text(
            'CAD',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.icon,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.bold = false,
  });

  final IconData icon;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: ProductFormView._fieldDecoration(),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.deepBlue),
          SizedBox(width: 8.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                icon: Icon(Icons.keyboard_arrow_down,
                    size: 20.sp, color: AppColors.grey),
                hint: Text(
                  hint,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.greyLight),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.textDark,
                ),
                borderRadius: BorderRadius.circular(14.r),
                dropdownColor: AppColors.white,
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSwitch extends StatelessWidget {
  const _AppSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.all(AppColors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primaryBlue
            : const Color(0xFFCBD5E1),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.index, required this.onRemove});

  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // TODO(backend): show the real uploaded image instead of this placeholder.
    final colors = index.isEven
        ? const [Color(0xFFEDE7DC), Color(0xFFC9BFB0)]
        : const [Color(0xFFD9DEE5), Color(0xFF9AA3AE)];
    return SizedBox(
      width: 100.w,
      height: 94.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: Icon(Icons.bed_outlined,
                  size: 34.sp, color: AppColors.white.withOpacity(0.8)),
            ),
          ),
          Positioned(
            top: 6.h,
            right: 6.w,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.close, size: 14.sp, color: AppColors.white),
              ),
            ),
          ),
          if (index < 2)
            Positioned(
              left: 6.w,
              bottom: 6.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: index == 0 ? AppColors.primaryBlue : AppColors.white,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  index == 0 ? 'COVER' : 'Side Profile',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: index == 0 ? AppColors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: AppColors.primaryBlue,
          radius: 16.r,
        ),
        child: Container(
          width: 100.w,
          height: 94.h,
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  size: 24.sp, color: AppColors.primaryBlue),
              SizedBox(height: 4.h),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                '(Max 5)',
                style: TextStyle(fontSize: 9.sp, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    const dash = 6.0;
    const gap = 4.0;
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
