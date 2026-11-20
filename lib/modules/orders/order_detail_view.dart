import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'order_detail_controller.dart';
import 'order_models.dart';

/// Order detail (owner): stepper, custom specs, items, payments, delivery and
/// timeline. Change Status and Record Payment open bottom sheets.
class OrderDetailView extends GetView<OrderDetailController> {
  const OrderDetailView({super.key});

  OrderDetail get _d => controller.detail.value;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                                child: Obx(_buildHeader),
              ),
              SizedBox(height: 14.h),
              Obx(_buildStepper),
              SizedBox(height: 10.h),
              const Divider(height: 1, color: AppColorsExtra.panelBorder),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  children: [
                                        Obx(
                      () => _d.spec == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: EdgeInsets.only(bottom: 14.h),
                              child: _buildSpecCard(_d.spec!),
                            ),
                    ),
                    Obx(_buildItemsCard),
                    SizedBox(height: 14.h),
                    Obx(_buildPaymentsCard),
                    SizedBox(height: 14.h),
                    Obx(_buildDeliveryCard),
                    SizedBox(height: 16.h),
                    const AuditNote(
                      'PCI-DSS Level 1 Encrypted · Seva POS v4.12',
                      icon: Icons.verified_outlined,
                    ),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader() {
    final sub = TextStyle(
      fontSize: 12.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textDark,
    );
    return Column(
      children: [
        Row(
          children: [
            BackPill(label: 'Orders', onTap: controller.onBackPressed),
            SizedBox(width: 8.w),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Order ${controller.number}',
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            CircleIconButton(
              icon: Icons.more_horiz,
              onTap: controller.onMorePressed,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.w,
          children: [
            Text(controller.customer, style: sub),
            _dot(),
            Icon(Icons.storefront, size: 14.sp, color: AppColors.primaryBlue),
            Text(
              _d.store,
              style: sub.copyWith(color: AppColors.primaryBlue),
            ),
            _dot(),
            Text(_d.placed, style: sub),
          ],
        ),
      ],
    );
  }

  Widget _dot() => Container(
        width: 4.w,
        height: 4.w,
        decoration: const BoxDecoration(
          color: AppColors.greyLight,
          shape: BoxShape.circle,
        ),
      );

  // ---------------- Status stepper ----------------
  Widget _buildStepper() {
    if (controller.status.value == OrderStatus.cancelled) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColorsExtra.dangerSoft,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColorsExtra.dangerBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.block, size: 18.sp, color: AppColors.danger),
              SizedBox(width: 8.w),
              Text(
                'This order was cancelled',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final current = controller.currentStep;
    const steps = OrderDetailController.steps;
    return SizedBox(
      height: 64.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: steps.length,
        itemBuilder: (_, i) {
          final done = i < current;
          final active = i == current;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 78.w,
                child: Column(
                  children: [
                    _stepCircle(i, done, active),
                    SizedBox(height: 6.h),
                    Text(
                      steps[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: active
                            ? FontWeight.w800
                            : (done ? FontWeight.w600 : FontWeight.w500),
                        color: active
                            ? AppColors.primaryBlue
                            : (done ? AppColors.textDark : AppColors.greyLight),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Padding(
                  padding: EdgeInsets.only(top: 15.h),
                  child: Container(
                    width: 14.w,
                    height: 2.5.h,
                    color: done ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepCircle(int i, bool done, bool active) {
    if (done) {
      return Container(
        width: 32.w,
        height: 32.w,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 18.sp, color: AppColors.white),
      );
    }
    if (active) {
      return Container(
        width: 34.w,
        height: 34.w,
        padding: EdgeInsets.all(2.5.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryBlue, width: 2),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.deepBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(controller.status.value.sheetIcon,
              size: 15.sp, color: AppColors.white),
        ),
      );
    }
    return Container(
      width: 24.w,
      height: 24.w,
      margin: EdgeInsets.all(4.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '${i + 1}',
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.greyLight,
        ),
      ),
    );
  }

  // ---------------- Custom specs ----------------
  Widget _buildSpecCard(CustomSpec s) {
    return SectionCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft blue corner glow like the design.
          Positioned(
            right: -60.w,
            top: -60.w,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glowBlue.withValues(alpha: 0.45),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBox(Icons.architecture),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Mattress Specification',
                          style: TextStyle(
                            fontSize: 16.5.sp,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          s.facility,
                          style: TextStyle(
                              fontSize: 11.5.sp, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 6.w),
                  const StatusPill(
                    text: 'Custom Cut',
                    dot: true,
                    fg: AppColorsExtra.amberText,
                    bg: AppColorsExtra.amberSoft,
                    border: AppColorsExtra.amberBorder,
                    fontSize: 10.5,
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _specTile('Dimensions', s.dimensions,
                        note: s.dimensionsNote, noteAccent: true),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _specTile('Cut Angle', s.cutAngle, note: s.cutNote),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              _specTile('Thickness & Core', s.thickness,
                  trailing: Icons.layers_outlined),
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
                decoration: BoxDecoration(
                  color: AppColorsExtra.panelGrey,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border(
                    left: BorderSide(color: AppColors.deepBlue, width: 3.w),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note,
                            size: 16.sp, color: AppColors.primaryBlue),
                        SizedBox(width: 6.w),
                        const Caption('Manufacturing notes',
                            color: AppColors.primaryBlue),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      s.notes,
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        height: 1.45,
                        color: AppColors.textDark.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              const Divider(color: AppColorsExtra.panelBorder),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.precision_manufacturing_outlined,
                      size: 16.sp, color: AppColors.primaryBlue),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      s.progress,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.onBlueprintPressed,
                    child: Row(
                      children: [
                        Text(
                          'Blueprint',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepBlue,
                          ),
                        ),
                        Icon(Icons.open_in_new,
                            size: 13.sp, color: AppColors.deepBlue),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon) => Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, size: 19.sp, color: AppColors.deepBlue),
      );

  Widget _specTile(
    String caption,
    String value, {
    String? note,
    bool noteAccent = false,
    IconData? trailing,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Caption(caption),
                SizedBox(height: 5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                if (note != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight:
                          noteAccent ? FontWeight.w600 : FontWeight.w400,
                      color: noteAccent
                          ? AppColors.primaryBlue
                          : AppColors.textDark.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            Icon(trailing, size: 20.sp, color: AppColors.deepBlue),
        ],
      ),
    );
  }

  // ---------------- Items & pricing ----------------
  Widget _buildItemsCard() {
    return SectionCard(
      child: Column(
        children: [
          CardTitle(
            icon: Icons.shopping_bag_outlined,
            title: 'Items & Pricing',
            trailing: StatusPill(
              text: '${_d.lines.length} items',
              fg: AppColors.deepBlue,
              bg: AppColors.lightBlue,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 14.h),
          ..._d.lines.map(_lineRow),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          _priceRow('Subtotal', '${formatCad(controller.subtotal)} CAD'),
          if (controller.discountCents.value > 0) ...[
            SizedBox(height: 10.h),
            _priceRow(
              controller.discountLabel,
              '-${formatCad(controller.discount)} CAD',
            ),
          ],          SizedBox(height: 10.h),
                    _priceRow(controller.gstLabel, '${formatCad(controller.gst)} CAD'),
          SizedBox(height: 10.h),
          _priceRow(controller.pstLabel, '${formatCad(controller.pst)} CAD'),
          SizedBox(height: 10.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Order Total',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                formatCad(controller.total),
                style: TextStyle(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              SizedBox(width: 4.w),
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(
                  'CAD',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineRow(OrderLine l) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.name,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  l.details,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${formatCad(l.price * l.qty)} CAD',
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool info = false}) {
    final style = TextStyle(fontSize: 13.sp, color: AppColors.textDark);
    return Row(
      children: [
        Text(label, style: style),
        if (info) ...[
          SizedBox(width: 4.w),
          Icon(Icons.info_outline, size: 13.sp, color: AppColors.grey),
        ],
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }

  // ---------------- Payments ----------------
  Widget _buildPaymentsCard() {
    final paid = controller.paid;
    final total = controller.total;
    final balance = controller.balance;
    final full = balance <= 0.004;
    final pct = (controller.paidRatio * 100).toStringAsFixed(1);
    final StatusPill pill = full
        ? const StatusPill(
            text: 'Paid in Full',
            fg: AppColors.success,
            bg: AppColorsExtra.successSoft,
            border: AppColorsExtra.successBorder,
            fontSize: 11,
          )
        : paid > 0
            ? const StatusPill(
                text: 'Partial Paid',
                fg: AppColorsExtra.amber,
                bg: AppColorsExtra.amberBg,
                border: AppColorsExtra.amberBorder,
                fontSize: 11,
              )
            : const StatusPill(
                text: 'Unpaid',
                fg: AppColors.danger,
                bg: AppColorsExtra.dangerSoft,
                border: AppColorsExtra.dangerBorder,
                fontSize: 11,
              );

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: Icons.payments_outlined,
            title: 'Payment Status',
            trailing: pill,
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.panelGrey,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColorsExtra.panelBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Paid ${formatCad(paid)} of ${formatCad(total)} CAD',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: full ? AppColors.success : AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ProgressBar(
                  value: controller.paidRatio,
                  color: full ? AppColors.success : AppColors.primaryBlue,
                ),
                SizedBox(height: 12.h),
                const Divider(color: AppColorsExtra.panelBorder),
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Caption(
                            full ? 'Balance' : 'Balance owing',
                            color: full
                                ? AppColors.success
                                : AppColorsExtra.amberText,
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            full
                                ? 'Nothing left to collect'
                                                                : controller.nextPaymentLabel,
                            style: TextStyle(
                                fontSize: 11.5.sp, color: AppColors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCad(balance),
                          style: TextStyle(
                            fontSize: 21.sp,
                            fontWeight: FontWeight.w800,
                            color: full
                                ? AppColors.success
                                : AppColorsExtra.amberText,
                          ),
                        ),
                        Text(
                          'CAD',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: full
                                ? AppColors.success
                                : AppColorsExtra.amberText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const Caption('Transaction history'),
          SizedBox(height: 8.h),
          if (controller.payments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No payments recorded yet',
                style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
              ),
            )
          else
            ...controller.payments.map(_paymentRow),
          SizedBox(height: 6.h),
          if (!full)
            SizedBox(
              width: double.infinity,
              child: SoftButton(
                label: 'Record Payment',
                icon: Icons.add_card,
                height: 46,
                fg: AppColors.primaryBlue,
                borderColor: AppColors.primaryBlue,
                fontSize: 13.5,
                onTap: controller.onRecordPaymentPressed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _paymentRow(PaymentRecord p) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(p.icon, size: 18.sp, color: AppColors.deepBlue),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.method,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${p.dateLabel} · ${p.kind}',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCad(p.amount),
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 12.sp, color: AppColors.success),
                  SizedBox(width: 3.w),
                  Text(
                    p.statusLabel,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Delivery & timeline ----------------
  Widget _buildDeliveryCard() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery & Timeline',
            trailing: GestureDetector(
              onTap: controller.onServiceAreaPressed,
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14.sp, color: AppColors.primaryBlue),
                  Text(
                    'Surrey Local',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          _infoRow(Icons.location_on_outlined, 'Destination', _d.destination,
              note: _d.destinationNote),
          _infoRow(Icons.calendar_today_outlined, 'Delivery window',
              _d.deliveryWindow),
          _infoRow(Icons.badge_outlined, 'Delivery team', _d.deliveryTeam,
              onTap: controller.onDeliveriesPressed),
          SizedBox(height: 4.h),
          const Caption('Timeline'),
          SizedBox(height: 10.h),
          ...List.generate(controller.timeline.length, (i) {
            return _timelineRow(
              controller.timeline[i],
              isLast: i == controller.timeline.length - 1,
            );
          }),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 13.sp, color: AppColors.grey),
              SizedBox(width: 5.w),
              Text(
                'This action is recorded in the audit log',
                style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String caption,
    String value, {
    String? note,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: const BoxDecoration(
                color: AppColorsExtra.panelGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15.sp, color: AppColors.grey),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Caption(caption),
                  SizedBox(height: 3.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (note != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18.sp, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _timelineRow(TimelineEvent e, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28.w,
            child: Column(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  margin: EdgeInsets.only(top: 3.h),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.done ? AppColors.success : AppColors.white,
                    border: Border.all(
                      color: e.done ? AppColors.success : AppColors.greyLight,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: e.done ? AppColorsExtra.successBorder : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: e.done ? AppColors.textDark : AppColors.grey,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${e.time} · ${e.by}',
                    style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Footer ----------------
  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      child: Column(
        children: [
          PrimaryArrowButton(
            label: 'Change Status',
            leadingIcon: Icons.published_with_changes,
            onPressed: controller.onChangeStatusPressed,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  label: 'Print Invoice',
                  icon: Icons.print_outlined,
                  height: 46,
                  fontSize: 13.5,
                  onTap: controller.onPrintInvoicePressed,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SoftButton(
                  label: 'Email Customer',
                  icon: Icons.mail_outline,
                  height: 46,
                  fontSize: 13.5,
                  onTap: controller.onEmailCustomerPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
