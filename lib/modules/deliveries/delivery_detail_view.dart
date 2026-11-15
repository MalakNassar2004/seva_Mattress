import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'delivery_detail_controller.dart';
import 'delivery_models.dart';

/// Delivery detail: order summary, drop-off info, driver & notes, and the
/// proof of completion (photos + signature).
class DeliveryDetailView extends GetView<DeliveryDetailController> {
  const DeliveryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Obx(() {
            final d = controller.delivery;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: _buildHeader(d),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                    children: [
                      if (d.status == DeliveryStatus.failed) ...[
                        _failedBanner(d),
                        SizedBox(height: 14.h),
                      ],
                      _buildOrderCard(d),
                      SizedBox(height: 14.h),
                      _buildDropOffCard(d),
                      SizedBox(height: 14.h),
                      _buildDriverCard(d),
                      SizedBox(height: 14.h),
                      _buildProofCard(d),
                      SizedBox(height: 16.h),
                      const AuditNote(
                        'Every dispatch and driver assignment is recorded in the audit log',
                      ),
                    ],
                  ),
                ),
                _buildFooter(d),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader(Delivery d) {
    return Column(
      children: [
        Row(
          children: [
            BackPill(label: 'Deliveries', onTap: controller.onBackPressed),
            const Spacer(),
            StatusPill(
              text: d.status.label,
              fg: d.status.fg,
              bg: d.status.bg,
              border: d.status.border,
              fontSize: 11.5,
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.customer,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${d.id} · ${controller.day.longLabel} · ${d.window}',
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            CircleIconButton(
              icon: Icons.call_outlined,
              iconColor: AppColors.primaryBlue,
              onTap: controller.onCallCustomerPressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _failedBanner(Delivery d) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.dangerSoft,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsExtra.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20.sp, color: AppColors.danger),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed Attempt · ${d.timeLabel ?? ''}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Reason: ${d.failReason ?? 'Not recorded'}',
                  style: TextStyle(fontSize: 12.5.sp, color: AppColors.danger),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Order summary ----------------
  Widget _buildOrderCard(Delivery d) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Order Summary',
            trailing: GestureDetector(
              onTap: controller.onOpenOrderPressed,
              child: Row(
                children: [
                  Text(
                    d.orderNumber,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 16.sp, color: AppColors.primaryBlue),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Container(
                width: 52.w,
                height: 52.w,
                decoration: BoxDecoration(
                  color: AppColorsExtra.chipGrey,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bed_outlined,
                        size: 21.sp, color: AppColors.deepBlue),
                    Text(
                      d.productTag,
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark.withValues(alpha: 0.7),
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
                      d.productName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      d.itemSummary,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColorsExtra.panelBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                'Order total',
                style: TextStyle(fontSize: 13.sp, color: AppColors.textDark),
              ),
              const Spacer(),
              Text(
                '${formatCad(d.amount)} CAD',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          d.paidInFull
              ? const StatusPill(
                  text: 'Paid in full · nothing to collect at door',
                  icon: Icons.check_circle_outline,
                  fg: AppColors.success,
                  bg: AppColorsExtra.successSoft,
                  border: AppColorsExtra.successBorder,
                  fontSize: 11,
                )
              : const StatusPill(
                  text: 'Balance owing · collect before unloading',
                  icon: Icons.warning_amber_rounded,
                  fg: AppColorsExtra.amberText,
                  bg: AppColorsExtra.amberSoft,
                  border: AppColorsExtra.amberBorder,
                  fontSize: 11,
                ),
        ],
      ),
    );
  }

  // ---------------- Drop-off ----------------
  Widget _buildDropOffCard(Delivery d) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.location_on_outlined, title: 'Drop-off'),
          SizedBox(height: 14.h),
          _infoRow(Icons.home_outlined, 'Address', d.address,
              note: [
                if (d.gateCode != null) 'Gate code: ${d.gateCode}',
                if (d.accessNote != null) d.accessNote!,
              ].join(' · ')),
          _infoRow(Icons.calendar_today_outlined, 'Delivery window',
              '${controller.day.longLabel} · ${d.window}'),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              if (d.twoPersonLift)
                const StatusPill(
                  text: '2-Person Lift',
                  icon: Icons.group_outlined,
                  fg: AppColorsExtra.amberText,
                  bg: AppColorsExtra.amberSoft,
                  border: AppColorsExtra.amberBorder,
                  fontSize: 11,
                ),
              if (d.whiteGlove)
                const StatusPill(
                  text: 'White Glove Setup',
                  icon: Icons.verified_outlined,
                  fg: AppColors.primaryBlue,
                  bg: AppColorsExtra.infoBg,
                  border: AppColorsExtra.infoBorder,
                  fontSize: 11,
                ),
              StatusPill(
                text: '${d.weightLbs} lbs',
                icon: Icons.scale_outlined,
                fg: AppColors.textDark,
                bg: AppColorsExtra.chipGrey,
                fontSize: 11,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String caption, String value, {String? note}) {
    return Padding(
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
                if (note != null && note.isNotEmpty) ...[
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
        ],
      ),
    );
  }

  // ---------------- Driver & notes ----------------
  Widget _buildDriverCard(Delivery d) {
    final dr = d.driver;
    return SectionCard(
      borderColor: dr == null ? AppColorsExtra.amberBorder : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardTitle(icon: Icons.badge_outlined, title: 'Driver & Notes'),
          SizedBox(height: 14.h),
          if (dr == null)
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColorsExtra.warningSoft,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColorsExtra.warningBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 20.sp, color: AppColorsExtra.amber),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Unassigned · no driver yet',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColorsExtra.amber,
                      ),
                    ),
                  ),
                  SoftButton(
                    label: 'Assign Driver',
                    filled: true,
                    radius: 22,
                    onTap: controller.onAssignPressed,
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                InitialsAvatar(
                  initials: dr.initials,
                  size: 44,
                  dotColor: dr.dotColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dr.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        dr.vehicle,
                        style:
                            TextStyle(fontSize: 12.sp, color: AppColors.grey),
                      ),
                      if (d.status == DeliveryStatus.outForDelivery &&
                          d.eta != null)
                        Text(
                          d.eta!,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
                CircleIconButton(
                  icon: Icons.call_outlined,
                  iconColor: AppColors.primaryBlue,
                  onTap: controller.onCallDriverPressed,
                ),
              ],
            ),
          SizedBox(height: 14.h),
          const Caption('Driver notes'),
          SizedBox(height: 8.h),
          if (d.driverNotes.isEmpty)
            Text(
              'No notes yet',
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.grey),
            )
          else
            ...d.driverNotes.map(
              (n) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.sticky_note_2_outlined,
                        size: 15.sp, color: AppColors.primaryBlue),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        n,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          height: 1.4,
                          color: AppColors.textDark.withValues(alpha: 0.85),
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
  }

  // ---------------- Proof of completion ----------------
  Widget _buildProofCard(Delivery d) {
    final done = d.status == DeliveryStatus.delivered;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardTitle(
            icon: Icons.task_alt,
            title: 'Proof of Completion',
            trailing: done && d.proofVerified
                ? const StatusPill(
                    text: 'Verified',
                    icon: Icons.verified_outlined,
                    fg: AppColors.success,
                    bg: AppColorsExtra.successSoft,
                    border: AppColorsExtra.successBorder,
                    fontSize: 11,
                  )
                : null,
          ),
          SizedBox(height: 14.h),
          if (!done)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColorsExtra.panelBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.photo_camera_outlined,
                      size: 26.sp, color: AppColors.greyLight),
                  SizedBox(height: 6.h),
                  Text(
                    'Photos and the customer signature appear here after drop-off',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(child: _photoThumb(0, Icons.bed_outlined, 'Set up')),
                SizedBox(width: 10.w),
                Expanded(
                    child: _photoThumb(1, Icons.door_front_door_outlined, 'Entry')),
                SizedBox(width: 10.w),
                Expanded(child: _signatureThumb()),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              'Captured ${d.timeLabel ?? ''} by ${d.driver?.shortName ?? 'driver'} · GPS matched to address',
              style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photoThumb(int i, IconData icon, String label) {
    return GestureDetector(
      onTap: () => controller.onProofTap(i),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.glowBlue, AppColors.splashMid],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(icon, size: 30.sp, color: AppColors.deepBlue),
              ),
              Positioned(
                left: 6.w,
                bottom: 6.h,
                child: StatusPill(
                  text: label,
                  icon: Icons.photo_camera_outlined,
                  fg: AppColors.white,
                  bg: Colors.black.withValues(alpha: 0.45),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signatureThumb() {
    return GestureDetector(
      onTap: () => controller.onProofTap(2),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: CustomPaint(painter: _SignaturePainter()),
                ),
              ),
              Positioned(
                left: 6.w,
                bottom: 6.h,
                child: StatusPill(
                  text: 'E-Sig',
                  icon: Icons.draw_outlined,
                  fg: AppColors.deepBlue,
                  bg: AppColors.lightBlue,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Footer ----------------
  Widget _buildFooter(Delivery d) {
    final Widget primary;
    Widget? secondary;
    switch (d.status) {
      case DeliveryStatus.pending:
      case DeliveryStatus.scheduled:
        primary = d.unassigned
            ? PrimaryArrowButton(
                label: 'Assign Driver',
                leadingIcon: Icons.person_add_alt_1_outlined,
                onPressed: controller.onAssignPressed,
              )
            : PrimaryArrowButton(
                label: 'Mark Out for Delivery',
                leadingIcon: Icons.local_shipping_outlined,
                onPressed: controller.onMarkOutPressed,
              );
        secondary = SoftButton(
          label: 'Reschedule',
          icon: Icons.edit_calendar_outlined,
          height: 46,
          fontSize: 13.5,
          onTap: controller.onReschedulePressed,
        );
      case DeliveryStatus.outForDelivery:
        primary = PrimaryArrowButton(
          label: 'Mark Delivered',
          leadingIcon: Icons.task_alt,
          onPressed: controller.onMarkDeliveredPressed,
        );
        secondary = SoftButton(
          label: 'Report Failed Attempt',
          icon: Icons.error_outline,
          height: 46,
          fontSize: 13.5,
          fg: AppColors.danger,
          borderColor: AppColorsExtra.dangerBorder,
          onTap: controller.onMarkFailedPressed,
        );
      case DeliveryStatus.failed:
        primary = PrimaryArrowButton(
          label: 'Reschedule Delivery',
          leadingIcon: Icons.edit_calendar_outlined,
          onPressed: controller.onReschedulePressed,
        );
      case DeliveryStatus.delivered:
        return SizedBox(height: 8.h);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
      child: Column(
        children: [
          primary,
          if (secondary != null) ...[
            SizedBox(height: 10.h),
            SizedBox(width: double.infinity, child: secondary),
          ],
        ],
      ),
    );
  }
}

/// Mock signature stroke for the proof thumbnail.
// TODO(backend): show the captured signature image.
class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.05, h * 0.6)
      ..cubicTo(w * 0.15, h * 0.2, w * 0.25, h * 0.2, w * 0.28, h * 0.55)
      ..cubicTo(w * 0.3, h * 0.8, w * 0.4, h * 0.3, w * 0.48, h * 0.45)
      ..cubicTo(w * 0.55, h * 0.6, w * 0.62, h * 0.25, w * 0.7, h * 0.5)
      ..cubicTo(w * 0.78, h * 0.7, w * 0.88, h * 0.35, w * 0.95, h * 0.4);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.deepBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(w * 0.05, h * 0.72),
      Offset(w * 0.95, h * 0.72),
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
