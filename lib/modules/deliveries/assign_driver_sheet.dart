import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/owner_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'deliveries_mock.dart';
import 'delivery_models.dart';

/// Result of the Assign Driver sheet: a driver, or a request to reschedule.
class AssignResult {
  const AssignResult.driver(Driver this.driver) : reschedule = false;
  const AssignResult.reschedule()
      : driver = null,
        reschedule = true;

  final Driver? driver;
  final bool reschedule;
}

class AssignDriverController extends GetxController {
  AssignDriverController(this.delivery);

  final Delivery delivery;

  // TODO(backend): load the drivers on shift with today's workload.
  static const List<Driver> drivers = DeliveriesMock.drivers;

  /// Preselects the current driver, else the recommended one.
  late final selected = drivers
      .indexWhere((d) =>
          d.name == delivery.driver?.name ||
          (delivery.driver == null && d.recommended))
      .obs;

  final error = RxnString();

  /// Drivers on shift in the area (busy ones included, like the design).
  int get activeCount => drivers.length;

  void select(int i) {
    selected.value = i;
    error.value = null;
  }

  void onConfirm() {
    if (selected.value < 0) {
      error.value = 'Select a driver';
      return;
    }
    Get.back(result: AssignResult.driver(drivers[selected.value]));
  }

  void onReschedulePressed() => Get.back(result: const AssignResult.reschedule());

  void onClosePressed() => Get.back();
}

/// Bottom sheet: Assign Driver & Dispatch. Open with AssignDriverSheet.open().
class AssignDriverSheet extends GetView<AssignDriverController> {
  const AssignDriverSheet({super.key});

  static Future<AssignResult?> open(Delivery delivery) async {
    Get.put(AssignDriverController(delivery));
    final result = await Get.bottomSheet<AssignResult>(
      const AssignDriverSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    Get.delete<AssignDriverController>();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final d = controller.delivery;
    return SheetFrame(
      footer: Obx(
        () {
          final i = controller.selected.value;
          final name = i < 0 ? null : AssignDriverController.drivers[i].shortName;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.error.value != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    controller.error.value!,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              PrimaryArrowButton(
                label: name == null ? 'Assign & Dispatch' : 'Assign $name & Dispatch',
                leadingIcon: Icons.local_shipping_outlined,
                onPressed: controller.onConfirm,
              ),
            ],
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10.w,
                  children: [
                    Text(
                      'Assign Driver & Dispatch',
                      style: TextStyle(
                        fontSize: 21.sp,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    StatusPill(
                      text: 'OWNER',
                      fg: AppColors.primaryBlue,
                      bg: AppColorsExtra.infoBg,
                      border: AppColorsExtra.infoBorder,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              SheetCloseButton(onTap: controller.onClosePressed),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Order ${d.orderNumber} · ${d.customer} · ${_city(d.address)}',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textDark.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColorsExtra.infoBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColorsExtra.infoBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule, size: 18.sp, color: AppColors.deepBlue),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '${DeliveriesMock.days[d.dayIndex].longLabel} · ${d.window}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _buildProductCard(d),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available Fleet Drivers Today',
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                width: 7.w,
                height: 7.w,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '${controller.activeCount} Active in Area',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Obx(
            () => Column(
              children: List.generate(
                AssignDriverController.drivers.length,
                (i) => _driverCard(
                  AssignDriverController.drivers[i],
                  controller.selected.value == i,
                  () => controller.select(i),
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: controller.onReschedulePressed,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColorsExtra.panelGrey,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColorsExtra.panelBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_calendar_outlined,
                      size: 19.sp, color: AppColors.textDark),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Need to reschedule or change date?',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down,
                      size: 20.sp, color: AppColors.grey),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          const AuditNote('Every driver assignment is recorded in the audit log'),
        ],
      ),
    );
  }

  static String _city(String address) {
    final parts = address.split(',');
    return parts.length > 1 ? parts[1].trim() : address;
  }

  Widget _buildProductCard(Delivery d) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.panelGrey,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColorsExtra.panelBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: AppColorsExtra.chipGrey,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bed_outlined,
                        size: 22.sp, color: AppColors.deepBlue),
                    Text(
                      d.productTag,
                      style: TextStyle(
                        fontSize: 8.5.sp,
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
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (d.whiteGlove) ...[
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 14.sp, color: AppColors.primaryBlue),
                          SizedBox(width: 4.w),
                          Text(
                            'White Glove Delivery',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 5.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14.sp, color: AppColors.grey),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            d.address,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textDark.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (d.gateCode != null || d.accessNote != null) ...[
                      SizedBox(height: 6.h),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6.w,
                        children: [
                          if (d.gateCode != null)
                            StatusPill(
                              text: 'Gate ${d.gateCode}',
                              fg: AppColors.textDark,
                              bg: AppColorsExtra.chipGrey,
                              fontSize: 10.5,
                            ),
                          if (d.accessNote != null)
                            Text(
                              '· ${d.accessNote}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.grey,
                              ),
                            ),
                        ],
                      ),
                    ],
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
              if (d.twoPersonLift)
                const StatusPill(
                  text: '2-Person Lift Required',
                  icon: Icons.group_outlined,
                  fg: AppColorsExtra.amberText,
                  bg: AppColorsExtra.amberSoft,
                  border: AppColorsExtra.amberBorder,
                  fontSize: 11,
                ),
              const Spacer(),
              Text(
                'Weight: ${d.weightLbs} lbs',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textDark.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _driverCard(Driver dr, bool selected, VoidCallback onTap) {
    final pct = (dr.load * 100).round();
    final StatusPill tag = switch (dr.state) {
      DriverState.full => const StatusPill(
          text: 'Full Workload',
          fg: AppColorsExtra.amberText,
          bg: AppColorsExtra.orangeBg,
          fontSize: 11,
        ),
      DriverState.available => const StatusPill(
          text: 'Available',
          fg: AppColors.primaryBlue,
          bg: AppColorsExtra.infoBg,
          fontSize: 11,
        ),
      DriverState.onRoute => StatusPill(
          text: '$pct% Capacity',
          fg: AppColors.success,
          bg: AppColorsExtra.successSoft,
          border: AppColorsExtra.successBorder,
          fontSize: 11,
        ),
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? AppColorsExtra.infoBg : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 10.h),
              child: RadioDot(selected: selected),
            ),
            SizedBox(width: 10.w),
            InitialsAvatar(
              initials: dr.initials,
              size: 42,
              bg: selected ? AppColors.lightBlue : AppColorsExtra.chipGrey,
              fg: selected ? AppColors.deepBlue : AppColors.textDark,
              dotColor: dr.dotColor,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        dr.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (dr.recommended)
                        StatusPill(
                          text: 'RECOMMENDED',
                          fg: AppColors.success,
                          bg: AppColorsExtra.successSoft,
                          fontSize: 9.5,
                          letterSpacing: 0.5,
                        ),
                      tag,
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    dr.vehicle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textDark.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        dr.state == DriverState.available
                            ? Icons.warehouse_outlined
                            : (dr.state == DriverState.full
                                ? Icons.schedule
                                : Icons.local_shipping_outlined),
                        size: 13.sp,
                        color: AppColors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text.rich(
                          TextSpan(children: [
                            if (dr.state != DriverState.available)
                              TextSpan(
                                text:
                                    '${dr.done} of ${dr.capacity} deliveries completed · ',
                              ),
                            TextSpan(
                              text: dr.note,
                              style: dr.state == DriverState.onRoute
                                  ? const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : null,
                            ),
                          ]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dr.state != DriverState.available) ...[
                    SizedBox(height: 8.h),
                    ProgressBar(
                      value: dr.load,
                      height: 5,
                      color: dr.isFull ? AppColors.warning : AppColors.success,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
