import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'order_form_controller.dart';
import 'order_models.dart';

/// Create Order / Quote (and Edit Quote).
class OrderFormView extends GetView<OrderFormController> {
  const OrderFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                child: _buildHeader(),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  children: [
                    if (!controller.isEdit) ...[
                      Obx(
                        () => SegmentedTabs(
                          labels: const ['Order', 'Quote'],
                          selectedIndex: controller.type.value,
                          onChanged: controller.selectType,
                        ),
                      ),
                      SizedBox(height: 14.h),
                    ],
                    _buildCustomerCard(),
                    SizedBox(height: 14.h),
                    _buildItemsCard(),
                    SizedBox(height: 14.h),
                    _buildCustomCard(),
                    SizedBox(height: 14.h),
                    Obx(_buildTermsCard),
                    SizedBox(height: 14.h),
                    Obx(_buildSummaryCard),
                    SizedBox(height: 14.h),
                    const AuditNote(
                      'Orders and quotes are recorded in the audit log',
                      icon: Icons.lock_outline,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
                child: Column(
                  children: [
                    Obx(() {
                      final err = controller.error.value;
                      if (err == null) return const SizedBox.shrink();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
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
                    Obx(() {
                      final isOrder =
                          controller.type.value == OrderFormController.orderType;
                      return PrimaryArrowButton(
                        label: controller.isEdit
                            ? 'Save Quote'
                            : (isOrder ? 'Create Order' : 'Save Quote'),
                        leadingIcon: isOrder
                            ? Icons.add_shopping_cart
                            : Icons.request_quote_outlined,
                        onPressed: controller.onSave,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Row(
      children: [
        BackPill(label: 'Orders', onTap: controller.onBackPressed),
        SizedBox(width: 10.w),
        Expanded(
          child: Obx(
            () => Text(
              controller.isEdit
                  ? 'Edit ${controller.editing!.number}'
                  : (controller.type.value == OrderFormController.orderType
                      ? 'New Order'
                      : 'New Quote'),
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        const StatusPill(
          text: 'CAD',
          fg: AppColors.deepBlue,
          bg: AppColors.lightBlue,
          fontSize: 11,
        ),
      ],
    );
  }

  // ---------------- Customer ----------------
  Widget _buildCustomerCard() {
    return SectionCard(
      child: Column(
        children: [
          CardTitle(
            icon: Icons.person_outline,
            title: 'Customer',
            trailing: GestureDetector(
              onTap: controller.onAddCustomerPressed,
              child: Text(
                '+ New',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Obx(
            () => Column(
              children: List.generate(OrderFormController.customers.length,
                  (i) {
                final c = OrderFormController.customers[i];
                final sel = controller.customerIndex.value == i;
                return GestureDetector(
                  onTap: () => controller.selectCustomer(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(10.w),
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
                        InitialsAvatar(initials: c.$1, size: 36),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.$2,
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                c.$3,
                                style: TextStyle(
                                    fontSize: 11.5.sp, color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                        RadioDot(selected: sel),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Items ----------------
  Widget _buildItemsCard() {
    return SectionCard(
      child: Column(
        children: [
          Obx(
            () => CardTitle(
              icon: Icons.shopping_bag_outlined,
              title: 'Items',
              trailing: StatusPill(
                text: '${controller.itemCount} selected',
                fg: AppColors.deepBlue,
                bg: AppColors.lightBlue,
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ...List.generate(
            OrderFormController.catalog.length,
            (i) => _itemRow(i, OrderFormController.catalog[i]),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(int i, OrderLine l) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColorsExtra.panelBorder),
            ),
            child: Icon(l.icon, size: 19.sp, color: AppColors.deepBlue),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${formatCad(l.price)} · ${l.details}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Obx(() {
            final q = controller.qty[i];
            return Row(
              children: [
                _qtyButton(Icons.remove, q > 0 ? () => controller.decrement(i) : null),
                SizedBox(
                  width: 28.w,
                  child: Text(
                    '$q',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: q > 0 ? AppColors.primaryBlue : AppColors.greyLight,
                    ),
                  ),
                ),
                _qtyButton(Icons.add, () => controller.increment(i)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: enabled ? AppColors.lightBlue : AppColorsExtra.panelGrey,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 16.sp,
            color: enabled ? AppColors.deepBlue : AppColors.greyLight),
      ),
    );
  }

  // ---------------- Custom specs ----------------
  Widget _buildCustomCard() {
    return SectionCard(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.architecture,
                    size: 20.sp, color: AppColors.primaryBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Custom Build',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: controller.isCustom.value,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: controller.toggleCustom,
                ),
              ],
            ),
            Text(
              'Non-standard size, angled cuts (RV, boat) or special core',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
            ),
            if (controller.isCustom.value) ...[
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: LabeledInput(
                      controller: controller.widthController,
                      label: 'Width',
                      hint: '72',
                      suffixText: 'in',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: LabeledInput(
                      controller: controller.lengthController,
                      label: 'Length',
                      hint: '80',
                      suffixText: 'in',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: LabeledInput(
                      controller: controller.angleController,
                      label: 'Cut angle',
                      hint: '45',
                      suffixText: '°',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: LabeledInput(
                      controller: controller.thicknessController,
                      label: 'Thickness',
                      hint: '10',
                      suffixText: 'in',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              LabeledInput(
                controller: controller.notesController,
                label: 'Manufacturing notes',
                hint: 'e.g. Reinforced perimeter edging',
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------- Deposit / validity ----------------
  Widget _buildTermsCard() {
    final isOrder = controller.type.value == OrderFormController.orderType;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: isOrder ? Icons.payments_outlined : Icons.event_outlined,
            title: isOrder ? 'Deposit' : 'Valid For',
          ),
          SizedBox(height: 12.h),
          if (isOrder)
            LabeledInput(
              controller: controller.depositController,
              hint: '0.00',
              prefixIcon: Icons.attach_money,
              suffixText: 'CAD',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: controller.onDepositChanged,
            )
          else
            Wrap(
              spacing: 8.w,
              children: List.generate(
                OrderFormController.validityOptions.length,
                (i) => ChoicePill(
                  label: '${OrderFormController.validityOptions[i]} days',
                  selected: controller.validityIndex.value == i,
                  onTap: () => controller.selectValidity(i),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Summary ----------------
  Widget _buildSummaryCard() {
    final isOrder = controller.type.value == OrderFormController.orderType;
    final style = TextStyle(fontSize: 13.sp, color: AppColors.textDark);
    Widget row(String a, String b) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(children: [Text(a, style: style), const Spacer(), Text(b, style: style)]),
        );

    return SectionCard(
      color: AppColorsExtra.panelGrey,
      borderColor: AppColorsExtra.panelBorder,
      child: Column(
        children: [
          row('Subtotal', '${formatCad(controller.subtotal)} CAD'),
          row('PST / GST (12% BC)', '${formatCad(controller.tax)} CAD'),
          if (isOrder && controller.deposit.value > 0)
            row('Deposit today', '-${formatCad(controller.deposit.value)} CAD'),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                isOrder ? 'Order Total' : 'Estimated Total',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${formatCad(controller.total)} CAD',
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
