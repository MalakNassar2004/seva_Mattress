import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';

/// Delivery lifecycle. Drives the summary chips, the card chips and the
/// card layout.
enum DeliveryStatus { pending, scheduled, outForDelivery, delivered, failed }

extension DeliveryStatusStyle on DeliveryStatus {
  String get label => switch (this) {
        DeliveryStatus.pending => 'Pending',
        DeliveryStatus.scheduled => 'Scheduled',
        DeliveryStatus.outForDelivery => 'Out for Delivery',
        DeliveryStatus.delivered => 'Delivered',
        DeliveryStatus.failed => 'Failed',
      };

  /// Short label on the summary chips.
  String get chipLabel =>
      this == DeliveryStatus.outForDelivery ? 'Out' : label;

  Color get fg => switch (this) {
        DeliveryStatus.pending => AppColors.textDark,
        DeliveryStatus.scheduled => AppColors.primaryBlue,
        DeliveryStatus.outForDelivery => AppColorsExtra.orange,
        DeliveryStatus.delivered => AppColors.success,
        DeliveryStatus.failed => AppColors.danger,
      };

  Color get bg => switch (this) {
        DeliveryStatus.pending => AppColorsExtra.chipGrey,
        DeliveryStatus.scheduled => AppColorsExtra.infoBg,
        DeliveryStatus.outForDelivery => AppColorsExtra.orangeBg,
        DeliveryStatus.delivered => AppColorsExtra.successSoft,
        DeliveryStatus.failed => AppColorsExtra.dangerSoft,
      };

  Color get border => switch (this) {
        DeliveryStatus.pending => AppColors.border,
        DeliveryStatus.scheduled => AppColorsExtra.infoBorder,
        DeliveryStatus.outForDelivery => AppColorsExtra.orangeBorder,
        DeliveryStatus.delivered => AppColorsExtra.successBorder,
        DeliveryStatus.failed => AppColorsExtra.dangerBorder,
      };
}

enum DriverState { onRoute, available, full }

/// A fleet driver shown in the Assign Driver sheet.
/// TODO(backend): replace with the real driver model.
class Driver {
  const Driver({
    required this.initials,
    required this.name,
    required this.shortName,
    required this.vehicle,
    required this.done,
    required this.capacity,
    required this.state,
    required this.note,
    this.phone = '(604) 555-0100',
    this.recommended = false,
  });

  final String initials;
  final String name;

  /// "Mike R." on the delivery cards.
  final String shortName;
  final String vehicle;

  /// Deliveries completed today.
  final int done;

  /// Deliveries planned today (capacity).
  final int capacity;
  final DriverState state;

  /// "On Route (Near White Rock)", "Shift ends 4:00 PM"...
  final String note;
  final String phone;
  final bool recommended;

  double get load => capacity == 0 ? 0 : done / capacity;
  bool get isFull => state == DriverState.full;

  Color get dotColor => switch (state) {
        DriverState.onRoute => AppColors.success,
        DriverState.available => AppColors.success,
        DriverState.full => AppColors.warning,
      };

  Driver copyWith({int? capacity}) => Driver(
        initials: initials,
        name: name,
        shortName: shortName,
        vehicle: vehicle,
        done: done,
        capacity: capacity ?? this.capacity,
        state: state,
        note: note,
        phone: phone,
        recommended: recommended,
      );
}

/// One stop on the dispatch board.
/// TODO(backend): replace with the real delivery model.
class Delivery {
  const Delivery({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.phone,
    required this.address,
    required this.itemSummary,
    required this.productName,
    required this.productTag,
    required this.amount,
    required this.dayIndex,
    required this.window,
    required this.status,
    this.driver,
    this.eta,
    this.timeLabel,
    this.failReason,
    this.gateCode,
    this.accessNote,
    this.weightLbs = 0,
    this.twoPersonLift = false,
    this.whiteGlove = false,
    this.proofVerified = false,
    this.driverNotes = const [],
    this.paidInFull = true,
  });

  final String id;
  final String orderNumber;
  final String customer;
  final String phone;
  final String address;
  final String itemSummary;
  final String productName;

  /// Short tag on the product thumbnail ("LATEX Q").
  final String productTag;
  final double amount;

  /// Index into the dispatch date strip.
  final int dayIndex;

  /// "10:00 AM - 1:00 PM".
  final String window;
  final DeliveryStatus status;
  final Driver? driver;

  /// "18 mins away" while out for delivery.
  final String? eta;

  /// "9:15 AM" when completed, "Yesterday 4:30 PM" when failed.
  final String? timeLabel;
  final String? failReason;
  final String? gateCode;
  final String? accessNote;
  final int weightLbs;
  final bool twoPersonLift;
  final bool whiteGlove;
  final bool proofVerified;
  final List<String> driverNotes;
  final bool paidInFull;

  bool get unassigned => driver == null;

  Delivery copyWith({
    DeliveryStatus? status,
    Driver? driver,
    bool clearDriver = false,
    int? dayIndex,
    String? window,
    String? failReason,
    bool clearFailReason = false,
    String? timeLabel,
    List<String>? driverNotes,
  }) =>
      Delivery(
        id: id,
        orderNumber: orderNumber,
        customer: customer,
        phone: phone,
        address: address,
        itemSummary: itemSummary,
        productName: productName,
        productTag: productTag,
        amount: amount,
        dayIndex: dayIndex ?? this.dayIndex,
        window: window ?? this.window,
        status: status ?? this.status,
        driver: clearDriver ? null : (driver ?? this.driver),
        eta: eta,
        timeLabel: timeLabel ?? this.timeLabel,
        failReason: clearFailReason ? null : (failReason ?? this.failReason),
        gateCode: gateCode,
        accessNote: accessNote,
        weightLbs: weightLbs,
        twoPersonLift: twoPersonLift,
        whiteGlove: whiteGlove,
        proofVerified: proofVerified,
        driverNotes: driverNotes ?? this.driverNotes,
        paidInFull: paidInFull,
      );
}

/// A day on the date strip.
class DispatchDay {
  const DispatchDay(this.weekday, this.day, this.month, {this.isToday = false});

  final String weekday;
  final int day;
  final String month;
  final bool isToday;

  String get longLabel => '${isToday ? 'Today' : weekday}, $month $day';
}

/// Result of the Reschedule sheet.
class RescheduleResult {
  const RescheduleResult({
    required this.deliveryId,
    required this.dayIndex,
    required this.window,
    required this.reason,
    required this.note,
    required this.notifyCustomer,
  });

  final String deliveryId;
  final int dayIndex;
  final String window;
  final String reason;
  final String note;
  final bool notifyCustomer;
}
