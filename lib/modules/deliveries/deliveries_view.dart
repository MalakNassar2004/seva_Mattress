import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_bottom_nav.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_shell_controller.dart';
import 'deliveries_controller.dart';
import 'delivery_models.dart';
import 'reschedule_sheet.dart';

/// Deliveries dispatch board (owner): date strip, status summary, and the
/// List | Route views. Shows the owner bottom navigation with Orders selected.
class DeliveriesView extends GetView<DeliveriesController> {
  const DeliveriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Obx(
                  () => ListView(
                    padding: EdgeInsets.fromLTRB(0, 12.h, 0, 16.h),
                    children: [
                      _pad(_buildHeader()),
                      SizedBox(height: 14.h),
                      _buildDateStrip(),
                      SizedBox(height: 12.h),
                      _buildSummaryChips(),
                      SizedBox(height: 12.h),
                      _pad(SegmentedTabs(
                        labels: const ['List', 'Route / Map'],
                        selectedIndex: controller.viewMode.value,
                        onChanged: controller.setViewMode,
                      )),
                      SizedBox(height: 14.h),
                      if (controller.viewMode.value ==
                          DeliveriesController.listMode)
                        ..._buildList()
                      else
                        _pad(_RouteView(controller: controller)),
                      SizedBox(height: 6.h),
                      _pad(const AuditNote(
                        'Every dispatch and driver assignment is recorded in the audit log',
                      )),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: PrimaryArrowButton(
                  label: '+  Schedule New Delivery',
                  onPressed: controller.onScheduleNewPressed,
                ),
              ),
              OwnerBottomNav(
                currentIndex: OwnerShellController.ordersTab,
                moreBadge: OwnerShellController.moreBadge,
                onTap: controller.onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pad(Widget child) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: child,
      );

  // ---------------- Header ----------------
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BackPill(label: 'More', onTap: controller.onBackPressed),
            const Spacer(),
            GestureDetector(
              onTap: controller.onStorePressed,
              child: const StatusPill(
                text: 'Surrey Floor #1',
                icon: Icons.storefront,
                fg: AppColors.deepBlue,
                bg: AppColorsExtra.infoBg,
                border: AppColorsExtra.infoBorder,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'Deliveries',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            GestureDetector(
              onTap: controller.onFleetLivePressed,
              child: const StatusPill(
                text: 'Fleet Live',
                dot: true,
                fg: AppColors.success,
                bg: AppColorsExtra.successSoft,
                border: AppColorsExtra.successBorder,
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 15.sp, color: AppColors.deepBlue),
            SizedBox(width: 6.w),
            Text(
              'Surrey Fleet Dispatch · Surrey Flagship (CAD)',
              style: TextStyle(
                fontSize: 12.5.sp,
                color: AppColors.textDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- Date strip ----------------
  Widget _buildDateStrip() {
    final selected = controller.selectedDay.value;
    return SizedBox(
      height: 62.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: DeliveriesController.days.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) => DayPill(
          day: DeliveriesController.days[i],
          selected: selected == i,
          onTap: () => controller.selectDay(i),
        ),
      ),
    );
  }

  // ---------------- Summary chips ----------------
  Widget _buildSummaryChips() {
    final sel = controller.statusFilter.value;
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: DeliveryStatus.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final s = DeliveryStatus.values[i];
          final active = sel == s;
          return GestureDetector(
            onTap: () => controller.toggleStatusFilter(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: active ? s.fg : s.border,
                  width: active ? 1.8 : 1,
                ),
              ),
              child: Text(
                '${s.chipLabel} (${controller.countFor(s)})',
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                  color: s.fg,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- List ----------------
  List<Widget> _buildList() {
    final list = controller.visible;
    if (list.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 36.h),
          child: Column(
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping_outlined,
                    size: 28.sp, color: AppColors.primaryBlue),
              ),
              SizedBox(height: 12.h),
              Text(
                'No deliveries for ${controller.day.longLabel}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return list
        .map((d) => Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
              child: DeliveryCard(
                delivery: d,
                dayLabel: controller.day.isToday ? 'Today' : controller.day.weekday,
                onTap: () => controller.onDeliveryTap(d),
                onAssign: () => controller.onAssignDriver(d),
                onReschedule: () => controller.onReschedule(d),
                onCall: d.driver == null
                    ? null
                    : () => controller.onCallDriver(d.driver!),
                onTrack: () => controller.onTrackRoute(d),
              ),
            ))
        .toList();
  }
}

// ---------------- Delivery card ----------------
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.dayLabel,
    required this.onTap,
    required this.onAssign,
    required this.onReschedule,
    required this.onTrack,
    this.onCall,
  });

  final Delivery delivery;
  final String dayLabel;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final VoidCallback onReschedule;
  final VoidCallback onTrack;
  final VoidCallback? onCall;

  bool get _needsDriver =>
      delivery.unassigned &&
      (delivery.status == DeliveryStatus.scheduled ||
          delivery.status == DeliveryStatus.pending);

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    final failed = d.status == DeliveryStatus.failed;
    final Color borderColor = failed
        ? AppColorsExtra.dangerBorder
        : (_needsDriver ? AppColorsExtra.amberBorder : AppColors.border);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: borderColor,
            width: _needsDriver ? 1.8 : 1.2,
          ),
          boxShadow: AppShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topRow(),
            SizedBox(height: 10.h),
            const Divider(color: AppColorsExtra.panelBorder),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    d.customer,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                StatusPill(
                  text: '${formatCad(d.amount, decimals: 0)} CAD',
                  fg: AppColors.deepBlue,
                  bg: AppColorsExtra.infoBg,
                  fontSize: 12,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              d.orderNumber,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16.sp,
                    color: d.status == DeliveryStatus.delivered
                        ? AppColors.grey
                        : AppColors.danger),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    d.address,
                    style: TextStyle(fontSize: 12.5.sp, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
            if (d.status != DeliveryStatus.delivered &&
                d.status != DeliveryStatus.failed) ...[
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColorsExtra.panelGrey,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColorsExtra.panelBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bed_outlined, size: 17.sp, color: AppColors.grey),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        d.itemSummary,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textDark.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 12.h),
            _bottom(),
          ],
        ),
      ),
    );
  }

  Widget _topRow() {
    final d = delivery;
    final IconData icon;
    final Color color;
    final String text;
    final Widget chip;

    switch (d.status) {
      case DeliveryStatus.delivered:
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        text = 'Completed · ${d.timeLabel ?? ''}';
        chip = _chip(d.status.label, d.status);
      case DeliveryStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.danger;
        text = 'Failed Attempt · ${d.timeLabel ?? ''}';
        chip = const StatusPill(
          text: 'Action Required',
          fg: AppColors.danger,
          bg: AppColorsExtra.dangerSoft,
          border: AppColorsExtra.dangerBorder,
          fontSize: 11,
        );
      case DeliveryStatus.pending:
        icon = Icons.hourglass_empty;
        color = AppColors.grey;
        text = 'Awaiting time slot';
        chip = _chip(d.status.label, d.status);
      default:
        icon = Icons.schedule;
        color = AppColors.primaryBlue;
        text = '$dayLabel · ${d.window}';
        chip = _chip(d.status.label, d.status);
    }
    final textColor = d.status == DeliveryStatus.failed
        ? AppColors.danger
        : AppColors.textDark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        chip,
      ],
    );
  }

  Widget _chip(String text, DeliveryStatus s) => StatusPill(
        text: text,
        fg: s.fg,
        bg: s.bg,
        border: s.border,
        fontSize: 11,
      );

  Widget _bottom() {
    final d = delivery;
    switch (d.status) {
      case DeliveryStatus.failed:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColorsExtra.dangerSoft,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColorsExtra.dangerBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_person_outlined,
                      size: 17.sp, color: AppColors.danger),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        const TextSpan(
                          text: 'Reason: ',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: d.failReason ?? 'Not recorded'),
                      ]),
                      style: TextStyle(fontSize: 12.sp, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: SoftButton(
                label: 'Reschedule Delivery',
                icon: Icons.edit_calendar_outlined,
                height: 48,
                radius: 24,
                fontSize: 13.5,
                onTap: onReschedule,
              ),
            ),
          ],
        );

      case DeliveryStatus.delivered:
        return Row(
          children: [
            Icon(Icons.local_shipping_outlined,
                size: 17.sp, color: AppColors.textDark),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                '${d.driver?.shortName ?? 'Driver'} · ${_vehicleShort(d.driver)}',
                style: TextStyle(fontSize: 13.sp, color: AppColors.textDark),
              ),
            ),
            if (d.proofVerified)
              const StatusPill(
                text: 'Photo & E-Sig Verified',
                icon: Icons.verified_outlined,
                fg: AppColors.success,
                bg: AppColorsExtra.successSoft,
                border: AppColorsExtra.successBorder,
                fontSize: 11,
              ),
          ],
        );

      default:
        if (d.unassigned) return _unassignedPanel();
        return _driverRow();
    }
  }

  Widget _unassignedPanel() {
    return Container(
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
              'No driver assigned yet',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColorsExtra.amber,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _pillButton('Assign Driver', onAssign, filled: true),
        ],
      ),
    );
  }

  Widget _driverRow() {
    final d = delivery;
    final dr = d.driver!;
    final out = d.status == DeliveryStatus.outForDelivery;
    return Row(
      children: [
        InitialsAvatar(
          initials: dr.initials,
          size: 34,
          bg: AppColors.primaryBlue,
          fg: AppColors.white,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dr.shortName} · ${_vehicleShort(dr)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              if (out && d.eta != null)
                Row(
                  children: [
                    Icon(Icons.near_me, size: 11.sp, color: AppColors.success),
                    SizedBox(width: 3.w),
                    Text(
                      d.eta!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: onAssign,
                  child: Text(
                    'Change driver',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (onCall != null)
          GestureDetector(
            onTap: onCall,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: const BoxDecoration(
                color: AppColorsExtra.chipGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.call_outlined,
                  size: 17.sp, color: AppColors.primaryBlue),
            ),
          ),
        SizedBox(width: 8.w),
        _pillButton(out ? 'Track Route ›' : 'Details ›', out ? onTrack : onTap,
            filled: true),
      ],
    );
  }

  Widget _pillButton(String label, VoidCallback onTap, {bool filled = false}) {
    return Material(
      color: filled ? AppColors.deepBlue : AppColors.white,
      borderRadius: BorderRadius.circular(22.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: filled ? AppColors.white : AppColors.deepBlue,
            ),
          ),
        ),
      ),
    );
  }

  /// "Truck #2 (Surrey Heavy Dispatch)" -> "Truck #2".
  static String _vehicleShort(Driver? d) =>
      d == null ? '' : d.vehicle.split('(').first.trim();
}

// ---------------- Route view ----------------
/// Schematic route of today's stops.
// TODO(backend): replace the drawing with a real map SDK and live GPS.
class _RouteView extends StatelessWidget {
  const _RouteView({required this.controller});

  final DeliveriesController controller;

  @override
  Widget build(BuildContext context) {
    final stops = controller.routeStops;
    return Column(
      children: [
        SectionCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: SizedBox(
              height: 250.h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _MapPainter(stops.length)),
                  ),
                  Positioned(
                    left: 12.w,
                    top: 12.h,
                    child: const StatusPill(
                      text: 'Surrey Warehouse',
                      icon: Icons.warehouse_outlined,
                      fg: AppColors.deepBlue,
                      bg: AppColors.white,
                      border: AppColors.border,
                      fontSize: 11,
                    ),
                  ),
                  Positioned(
                    right: 12.w,
                    bottom: 12.h,
                    child: StatusPill(
                      text: '${stops.length} stops · live',
                      dot: true,
                      fg: AppColors.success,
                      bg: AppColors.white,
                      border: AppColorsExtra.successBorder,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        if (stops.isEmpty)
          Text(
            'No active stops on this day',
            style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
          )
        else
          SectionCard(
            child: Column(
              children: List.generate(stops.length, (i) {
                final d = stops[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.onDeliveryTap(d),
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i == stops.length - 1 ? 0 : 14.h),
                    child: Row(
                      children: [
                        Container(
                          width: 28.w,
                          height: 28.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: d.status.fg,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.customer,
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                '${d.window} · ${d.driver?.shortName ?? 'Unassigned'}',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: d.unassigned
                                      ? AppColorsExtra.amber
                                      : AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          text: d.status.chipLabel,
                          fg: d.status.fg,
                          bg: d.status.bg,
                          fontSize: 10.5,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.stops);

  final int stops;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFF4FA),
    );

    // Streets.
    final street = Paint()
      ..color = AppColors.white
      ..strokeWidth = 9;
    for (var x = 30.0; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x + 20, size.height), street);
    }
    for (var y = 40.0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 12), street);
    }

    // Park and water.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.08, 70, 50),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFDDF1E3),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.85)
        ..quadraticBezierTo(size.width * 0.3, size.height * 0.75,
            size.width * 0.55, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFFD6E8F8),
    );

    // Route.
    final points = <Offset>[
      Offset(size.width * 0.14, size.height * 0.22),
      Offset(size.width * 0.38, size.height * 0.42),
      Offset(size.width * 0.62, size.height * 0.36),
      Offset(size.width * 0.8, size.height * 0.62),
      Offset(size.width * 0.52, size.height * 0.7),
    ];
    final count = (stops + 1).clamp(1, points.length);
    final route = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < count; i++) {
      route.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.primaryBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Warehouse + stops.
    for (var i = 0; i < count; i++) {
      final p = points[i];
      canvas.drawCircle(p, 11, Paint()..color = AppColors.white);
      canvas.drawCircle(
        p,
        8,
        Paint()..color = i == 0 ? AppColors.deepBlue : AppColors.primaryBlue,
      );
      if (i > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$i',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.stops != stops;
}
