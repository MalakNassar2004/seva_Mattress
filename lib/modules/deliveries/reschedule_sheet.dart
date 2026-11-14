import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';
import '../../app/widgets/app_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import 'deliveries_mock.dart';
import 'delivery_models.dart';

/// Reschedule a delivery (failed or moved), or schedule a pending one.
class RescheduleController extends GetxController {
  RescheduleController({this.delivery, this.candidates = const []});

  /// The delivery being rescheduled. null = schedule mode (pick from
  /// [candidates]).
  final Delivery? delivery;
  final List<Delivery> candidates;

  static const List<DispatchDay> days = DeliveriesMock.days;
  static const int todayIndex = DeliveriesMock.todayIndex;
  static const List<String> windows = DeliveriesMock.windows;
  static const List<String> reasons = DeliveriesMock.failReasons;

  bool get isSchedule => delivery == null;
  bool get isFailed => delivery?.status == DeliveryStatus.failed;

  /// A failed delivery must say why it failed.
  bool get reasonRequired => isFailed;

  // ---------------- State ----------------
  final candidateIndex = 0.obs;
  final selectedReasons = <String>{}.obs;
  late final dayIndex = (delivery == null || delivery!.dayIndex <= todayIndex
          ? todayIndex + 1
          : delivery!.dayIndex)
      .clamp(todayIndex, days.length - 1)
      .obs;
  late final windowIndex =
      (windows.contains(delivery?.window) ? windows.indexOf(delivery!.window) : 1)
          .obs;
  final notifyCustomer = true.obs;
  final noteController = TextEditingController();
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    // Prefill the reasons recorded by the driver on a failed attempt.
    final r = delivery?.failReason;
    if (r != null) {
      for (final part in r.split('/')) {
        final p = part.trim();
        if (reasons.contains(p)) selectedReasons.add(p);
      }
    }
  }

  Delivery? get target =>
      isSchedule ? (candidates.isEmpty ? null : candidates[candidateIndex.value]) : delivery;

  // ---------------- Actions ----------------
  void selectCandidate(int i) => candidateIndex.value = i;

  void toggleReason(String r) {
    if (!selectedReasons.remove(r)) selectedReasons.add(r);
    error.value = null;
  }

  void selectDay(int i) => dayIndex.value = i;
  void selectWindow(int i) => windowIndex.value = i;
  void toggleNotify(bool v) => notifyCustomer.value = v;

  /// Opens the full calendar. Only the days on the dispatch board can be
  /// picked in the mock.
  Future<void> onPickDatePressed(BuildContext context) async {
    // TODO(backend): allow any future date once the API returns slots.
    DateTime toDate(DispatchDay d) => DateTime(2024, 10, d.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate(days[dayIndex.value]),
      firstDate: toDate(days[todayIndex]),
      lastDate: toDate(days.last),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final i = days.indexWhere((d) => d.day == picked.day);
    if (i >= 0) dayIndex.value = i;
  }

  void onConfirm() {
    final t = target;
    if (t == null) return;
    if (reasonRequired && selectedReasons.isEmpty) {
      error.value = 'Select why the delivery failed';
      return;
    }
    Get.back(
      result: RescheduleResult(
        deliveryId: t.id,
        dayIndex: dayIndex.value,
        window: windows[windowIndex.value],
        reason: selectedReasons.join(' / '),
        note: noteController.text.trim(),
        notifyCustomer: notifyCustomer.value,
      ),
    );
  }

  void onClosePressed() => Get.back();

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}

/// Bottom sheet: Reschedule Delivery / Schedule Delivery.
class RescheduleSheet extends GetView<RescheduleController> {
  const RescheduleSheet({super.key});

  /// Reschedule one delivery (failed attempt or change of date).
  static Future<RescheduleResult?> open({required Delivery delivery}) =>
      _open(RescheduleController(delivery: delivery));

  /// Schedule one of the pending deliveries.
  static Future<RescheduleResult?> openSchedule(List<Delivery> pending) =>
      _open(RescheduleController(candidates: pending));

  static Future<RescheduleResult?> _open(RescheduleController c) async {
    Get.put(c);
    final result = await Get.bottomSheet<RescheduleResult>(
      const RescheduleSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
    );
    Get.delete<RescheduleController>();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return SheetFrame(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            final err = c.error.value;
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
          PrimaryArrowButton(
            label: c.isSchedule ? 'Schedule Delivery' : 'Confirm New Date',
            leadingIcon: Icons.event_available,
            onPressed: c.onConfirm,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.isSchedule ? 'Schedule Delivery' : 'Reschedule Delivery',
                  style: TextStyle(
                    fontSize: 21.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              SheetCloseButton(onTap: c.onClosePressed),
            ],
          ),
          if (!c.isSchedule) ...[
            SizedBox(height: 4.h),
            Text(
              'Order ${c.delivery!.orderNumber} · ${c.delivery!.customer}',
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
            ),
          ],
          SizedBox(height: 14.h),
          if (c.isFailed) ...[
            _failedBanner(c.delivery!),
            SizedBox(height: 16.h),
          ],
          if (c.isSchedule) ...[
            _label('Order waiting for a slot'),
            Obx(
              () => Column(
                children: List.generate(c.candidates.length, (i) {
                  final d = c.candidates[i];
                  return _candidateRow(
                      d, c.candidateIndex.value == i, () => c.selectCandidate(i));
                }),
              ),
            ),
            SizedBox(height: 10.h),
          ] else ...[
            _label(c.reasonRequired ? 'Reason for failed attempt' : 'Reason (optional)'),
            Obx(
              () => Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: RescheduleController.reasons
                    .map((r) => ChoicePill(
                          label: r,
                          selected: c.selectedReasons.contains(r),
                          onTap: () => c.toggleReason(r),
                          selectedFg: AppColors.danger,
                          selectedBg: AppColorsExtra.dangerSoft,
                          selectedBorder: AppColorsExtra.dangerBorder,
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 18.h),
          ],
          Row(
            children: [
              Expanded(child: _label('New date')),
              GestureDetector(
                onTap: () => c.onPickDatePressed(context),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 16.sp, color: AppColors.primaryBlue),
                      SizedBox(width: 4.w),
                      Text(
                        'Calendar',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            // Read before the lazy itemBuilder so Obx subscribes to it.
            final selected = c.dayIndex.value;
            return SizedBox(
              height: 62.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: RescheduleController.days.length -
                    RescheduleController.todayIndex,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (_, k) {
                  final i = k + RescheduleController.todayIndex;
                  return DayPill(
                    day: RescheduleController.days[i],
                    selected: selected == i,
                    onTap: () => c.selectDay(i),
                  );
                },
              ),
            );
          }),
          SizedBox(height: 16.h),
          _label('Time window'),
          Obx(
            () => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(
                RescheduleController.windows.length,
                (i) => ChoicePill(
                  label: RescheduleController.windows[i],
                  icon: Icons.schedule,
                  selected: c.windowIndex.value == i,
                  onTap: () => c.selectWindow(i),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          LabeledInput(
            controller: c.noteController,
            label: 'Note for driver (optional)',
            hint: 'e.g. Call on arrival, gate code changed',
            maxLines: 2,
          ),
          SizedBox(height: 12.h),
          Obx(
            () => Row(
              children: [
                Icon(Icons.sms_outlined, size: 18.sp, color: AppColors.grey),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Text the customer the new time',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: c.notifyCustomer.value,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: c.toggleNotify,
                ),
              ],
            ),
          ),
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

  Widget _failedBanner(Delivery d) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsExtra.dangerSoft,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsExtra.dangerBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18.sp, color: AppColors.danger),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Failed attempt · ${d.timeLabel ?? ''}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateRow(Delivery d, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: selected ? AppColorsExtra.infoBg : AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${d.customer} · ${d.orderNumber}',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    d.itemSummary,
                    style: TextStyle(fontSize: 11.5.sp, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// Day pill used by the dispatch date strip and the reschedule sheet.
/// Selected = primary blue pill.
class DayPill extends StatelessWidget {
  const DayPill({
    super.key,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DispatchDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(minWidth: 54.w),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? AppColors.deepBlue : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.isToday ? 'Today' : day.weekday,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppColors.white.withValues(alpha: 0.9)
                    : AppColors.textDark.withValues(alpha: 0.75),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              day.isToday ? '${day.weekday} ${day.day}' : '${day.day}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
