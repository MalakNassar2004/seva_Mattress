import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../products/product_item.dart';
import 'order_form_controller.dart';
import 'order_models.dart';

/// false = Quotes are hidden (they are not built yet). Set to true to show
/// the Order | Quote switch again.
const bool _quotesEnabled = false;

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
                    if (!controller.isEdit && _quotesEnabled) ...[
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
                    Obx(_buildDiscountCard),
                    SizedBox(height: 14.h),
                    Obx(_buildTermsCard),
                    Obx(_buildDeliveryCard),
                    SizedBox(height: 14.h),
                    Obx(_buildSummaryCard),
                    SizedBox(height: 14.h),
                    const AuditNote(
                      'Orders are recorded in the audit log',
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
                          textAlign: TextAlign.center,
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
                        label: controller.isSaving.value
                            ? 'Saving...'
                            : (controller.isEdit
                                ? 'Save Quote'
                                : (isOrder ? 'Create Order' : 'Save Quote')),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          LabeledInput(
            controller: controller.phoneController,
            label: 'Customer phone',
            hint: '(604) 555-0192',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: controller.onPhoneChanged,
          ),
          SizedBox(height: 10.h),
          Obx(_buildCustomerState),
        ],
      ),
    );
  }

  Widget _buildCustomerState() {
    final state = controller.phoneState.value;
    final grey = TextStyle(fontSize: 12.sp, height: 1.35, color: AppColors.grey);

    switch (state) {
      case PhoneState.empty:
        return Text(
          'Type the phone to find the customer, or to add a new one. Leave it '
          'empty for a walk-in sale that is paid in full.',
          style: grey,
        );
      case PhoneState.incomplete:
        return Text('Keep typing the phone number...', style: grey);
      case PhoneState.checking:
        return Row(
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8.w),
            Text('Looking for the customer...', style: grey),
          ],
        );
      case PhoneState.found:
        final c = controller.customer.value;
        if (c == null) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColorsExtra.infoBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.primaryBlue, width: 1.6),
          ),
          child: Row(
            children: [
              InitialsAvatar(initials: c.initials, size: 36),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${c.phone} · ${c.city}',
                      style: TextStyle(
                          fontSize: 11.5.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
              RadioDot(selected: true),
            ],
          ),
        );
      case PhoneState.notFound:
        return Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColorsExtra.panelGrey,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColorsExtra.panelBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_add_alt_1_outlined,
                      size: 16.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'New customer. It is saved with this order.',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              LabeledInput(
                controller: controller.newNameController,
                label: 'Full name',
                hint: 'e.g. David Thompson',
                prefixIcon: Icons.person_outline,
              ),
              SizedBox(height: 10.h),
              LabeledInput(
                controller: controller.newCityController,
                label: 'City',
                hint: 'e.g. Surrey',
                prefixIcon: Icons.location_city_outlined,
              ),
            ],
          ),
        );
    }
  }

  // ---------------- Items ----------------
  Widget _buildItemsCard() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          OwnerSearchField(
            hint: 'Search product, SKU or scan...',
            onChanged: controller.onProductQueryChanged,
            onScan: controller.onScanProduct,
          ),
          SizedBox(height: 12.h),
          Obx(_buildItemsBody),
        ],
      ),
    );
  }

  Widget _buildItemsBody() {
    final lines = controller.lines;
    final results = controller.results;
    final hasQuery = controller.query.value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) _lineRow(i, lines[i]),
        if (lines.isEmpty && !hasQuery)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Text(
              'Search a product by name or SKU, or scan its barcode.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
            ),
          ),
        if (hasQuery) ...[
          if (lines.isNotEmpty) SizedBox(height: 6.h),
          const Caption('Results'),
          SizedBox(height: 8.h),
          if (results.isEmpty)
            Text(
              'No product matches your search.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
            )
          else
            for (final p in results) _resultRow(p),
        ],
      ],
    );
  }

  Widget _lineRow(int i, CartLine l) {
    final p = l.product;
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
            child: Icon(
              p.kind == ProductKind.pillow
                  ? Icons.airline_seat_flat_outlined
                  : Icons.bed_outlined,
              size: 19.sp,
              color: AppColors.deepBlue,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${formatCad(p.price)} · SKU ${p.sku}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Row(
            children: [
              _qtyButton(Icons.remove, () => controller.decrementAt(i)),
              SizedBox(
                width: 28.w,
                child: Text(
                  '${l.qty}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              _qtyButton(Icons.add, () => controller.incrementAt(i)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultRow(ProductItem p) {
    final available = p.available;
    final Color fg = available <= 0
        ? AppColors.danger
        : available <= kLowStockThreshold
            ? AppColors.warning
            : AppColors.success;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.addProduct(p),
      child: Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.add, size: 19.sp, color: AppColors.deepBlue),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${formatCad(p.price)} · SKU ${p.sku}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              available <= 0 ? 'Out of stock' : 'In stock $available',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: const BoxDecoration(
          color: AppColors.lightBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.sp, color: AppColors.deepBlue),
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
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: LabeledInput(
                      controller: controller.lengthController,
                      label: 'Length',
                      hint: '80',
                      suffixText: 'in',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
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
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
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

  // ---------------- A tappable date field ----------------
  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
    String hint = 'Choose a date',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Caption(label),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
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
                    value == null ? hint : fmtOrderDate(value),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          value == null ? FontWeight.w400 : FontWeight.w700,
                      color:
                          value == null ? AppColors.grey : AppColors.textDark,
                    ),
                  ),
                ),
                if (value != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close, size: 17.sp, color: AppColors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Discount (owner only) ----------------
  Widget _buildDiscountCard() {
    if (controller.type.value != OrderFormController.orderType) {
      return const SizedBox.shrink();
    }
    final owner = controller.isOwner.value;
    final percent = controller.discountPercent.value;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: Icons.local_offer_outlined,
            title: 'Discount',
            trailing: owner
                ? null
                : const StatusPill(
                    text: 'Owner only',
                    icon: Icons.lock_outline,
                    fg: AppColors.grey,
                    bg: AppColorsExtra.chipGrey,
                    fontSize: 11,
                  ),
          ),
          SizedBox(height: 12.h),
          if (!owner)
            Text(
              'Only the owner can give a discount.',
              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
            )
          else ...[
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                ChoicePill(
                  label: 'Percent %',
                  selected: percent,
                  onTap: () => controller.setDiscountKind(true),
                ),
                ChoicePill(
                  label: 'Amount \$',
                  selected: !percent,
                  onTap: () => controller.setDiscountKind(false),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            LabeledInput(
              controller: controller.discountController,
              hint: percent ? '10' : '0.00',
              prefixIcon: percent ? Icons.percent : Icons.attach_money,
              suffixText: percent ? '%' : 'CAD',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: controller.onDiscountChanged,
            ),
            SizedBox(height: 10.h),
            LabeledInput(
              controller: controller.discountReasonController,
              label: 'Reason (required with a discount)',
              hint: 'e.g. Loyal customer, floor model',
              maxLines: 2,
            ),
            SizedBox(height: 8.h),
            Text(
              'The tax is worked out after the discount.',
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
            ),
          ],
        ],
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
            title: isOrder ? 'Payment today' : 'Valid For',
          ),
          SizedBox(height: 12.h),
          if (isOrder) ...[
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                ChoicePill(
                  label: 'Full amount',
                  selected: false,
                  onTap: controller.onPayFull,
                ),
                ChoicePill(
                  label: '50%',
                  selected: false,
                  onTap: controller.onPayHalf,
                ),
                ChoicePill(
                  label: 'No deposit',
                  selected: false,
                  onTap: controller.onNoDeposit,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            LabeledInput(
              controller: controller.depositController,
              hint: '0.00',
              prefixIcon: Icons.attach_money,
              suffixText: 'CAD',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: controller.onDepositChanged,
            ),
            SizedBox(height: 12.h),
            const Caption('Payment method'),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(
                OrderFormController.paymentMethods.length,
                (i) => ChoicePill(
                  label: OrderFormController.paymentMethods[i],
                  selected: controller.depositMethodIndex.value == i,
                  onTap: () => controller.selectDepositMethod(i),
                ),
              ),
            ),
            // A balance is left: when is the next payment due?
            if (controller.needsNextPayment) ...[
              SizedBox(height: 14.h),
              _dateField(
                label: 'Next payment date',
                value: controller.nextPaymentDate.value,
                onTap: controller.pickNextPaymentDate,
                hint: 'Choose when the next payment is due',
              ),
            ],
          ] else
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

  // ---------------- Delivery date (orders only) ----------------
  Widget _buildDeliveryCard() {
    if (controller.type.value != OrderFormController.orderType) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardTitle(
              icon: Icons.local_shipping_outlined,
              title: 'Delivery',
            ),
            SizedBox(height: 12.h),
            _dateField(
              label: 'Delivery date (optional)',
              value: controller.deliveryDate.value,
              onTap: controller.pickDeliveryDate,
              onClear: controller.clearDeliveryDate,
              hint: 'Choose the delivery date',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Summary ----------------
  Widget _buildSummaryCard() {
    final isOrder = controller.type.value == OrderFormController.orderType;
    final style = TextStyle(fontSize: 13.sp, color: AppColors.textDark);
    Widget row(String a, String b) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(children: [
            Text(a, style: style),
            const Spacer(),
            Text(b, style: style),
          ]),
        );

    return SectionCard(
      color: AppColorsExtra.panelGrey,
      borderColor: AppColorsExtra.panelBorder,
      child: Column(
        children: [
          row('Subtotal', '${formatCad(controller.subtotal)} CAD'),
          if (controller.discountCents > 0)
            row('Discount', '-${formatCad(controller.discount)} CAD'),
          row(controller.gstLabel, '${formatCad(controller.gst)} CAD'),
          row(controller.pstLabel, '${formatCad(controller.pst)} CAD'),
          if (isOrder && controller.deposit.value > 0)
            row('Paid today', '-${formatCad(controller.deposit.value)} CAD'),
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