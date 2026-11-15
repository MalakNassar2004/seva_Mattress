import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';

/// Order lifecycle. Drives the status chips, the stepper and the
/// Change Status sheet.
enum OrderStatus { newOrder, inProduction, ready, outForDelivery, delivered, cancelled }

extension OrderStatusStyle on OrderStatus {
  String get label => switch (this) {
        OrderStatus.newOrder => 'New',
        OrderStatus.inProduction => 'In Production',
        OrderStatus.ready => 'Ready',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  /// Text on the order card chip.
  String get cardLabel =>
      this == OrderStatus.ready ? 'Ready for Delivery' : label;

  String get description => switch (this) {
        OrderStatus.newOrder => 'Order placed, waiting for deposit or review',
        OrderStatus.inProduction => 'Being cut and assembled at the facility',
        OrderStatus.ready => 'Finished and waiting at the warehouse',
        OrderStatus.outForDelivery => 'Loaded on a truck with a driver',
        OrderStatus.delivered => 'Received by the customer',
        OrderStatus.cancelled => 'Order stopped. Refunds handled separately',
      };

  Color get fg => switch (this) {
        OrderStatus.newOrder => AppColors.primaryBlue,
        OrderStatus.inProduction => AppColors.warning,
        OrderStatus.ready => AppColors.success,
        OrderStatus.outForDelivery => AppColorsExtra.orange,
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.danger,
      };

  Color get bg => switch (this) {
        OrderStatus.newOrder => AppColorsExtra.infoBg,
        OrderStatus.inProduction => AppColorsExtra.amberSoft,
        OrderStatus.ready => AppColorsExtra.successSoft,
        OrderStatus.outForDelivery => AppColorsExtra.orangeBg,
        OrderStatus.delivered => AppColorsExtra.successSoft,
        OrderStatus.cancelled => AppColorsExtra.dangerSoft,
      };

  Color get border => switch (this) {
        OrderStatus.newOrder => AppColorsExtra.infoBorder,
        OrderStatus.inProduction => AppColorsExtra.amberBorder,
        OrderStatus.ready => AppColorsExtra.successBorder,
        OrderStatus.outForDelivery => AppColorsExtra.orangeBorder,
        OrderStatus.delivered => AppColorsExtra.successBorder,
        OrderStatus.cancelled => AppColorsExtra.dangerBorder,
      };

  /// null = the chip shows a dot instead of an icon.
  IconData? get icon => switch (this) {
        OrderStatus.newOrder => null,
        OrderStatus.inProduction => null,
        OrderStatus.ready => Icons.local_shipping_outlined,
        OrderStatus.outForDelivery => Icons.local_shipping,
        OrderStatus.delivered => Icons.check_circle_outline,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  IconData get sheetIcon => switch (this) {
        OrderStatus.newOrder => Icons.receipt_long_outlined,
        OrderStatus.inProduction => Icons.precision_manufacturing_outlined,
        OrderStatus.ready => Icons.inventory_2_outlined,
        OrderStatus.outForDelivery => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.task_alt,
        OrderStatus.cancelled => Icons.block,
      };
}

/// One card of the Orders list.
/// TODO(backend): replace with the real order model.
class OrderItem {
  const OrderItem({
    required this.number,
    required this.product,
    required this.customer,
    required this.city,
    required this.status,
    required this.dateLabel,
    required this.total,
    required this.paid,
    required this.footerIcon,
    required this.footerText,
    this.isCustom = false,
    this.dateIsWindow = false,
    this.footerIconColor = AppColors.grey,
    this.footerRight,
    this.footerRightAccent = false,
  });

  final String number;
  final String product;
  final String customer;
  final String city;
  final OrderStatus status;
  final bool isCustom;

  /// "Due Oct 26, 2024" or a delivery window ("Today, 2:00 PM - 5:00 PM").
  final String dateLabel;
  final bool dateIsWindow;
  final double total;
  final double paid;

  final IconData footerIcon;
  final Color footerIconColor;
  final String footerText;
  final String? footerRight;
  final bool footerRightAccent;

  double get balance => (total - paid).clamp(0, double.infinity).toDouble();
  double get paidRatio => total == 0 ? 0 : (paid / total).clamp(0, 1);
  bool get paidInFull => balance <= 0.004;

  OrderItem copyWith({OrderStatus? status, double? paid}) => OrderItem(
        number: number,
        product: product,
        customer: customer,
        city: city,
        status: status ?? this.status,
        dateLabel: dateLabel,
        total: total,
        paid: paid ?? this.paid,
        footerIcon: footerIcon,
        footerText: footerText,
        isCustom: isCustom,
        dateIsWindow: dateIsWindow,
        footerIconColor: footerIconColor,
        footerRight: footerRight,
        footerRightAccent: footerRightAccent,
      );
}

enum QuoteStatus { draft, sent, expiring }

extension QuoteStatusStyle on QuoteStatus {
  String get label => switch (this) {
        QuoteStatus.draft => 'Draft',
        QuoteStatus.sent => 'Sent',
        QuoteStatus.expiring => 'Expiring Soon',
      };
}

/// One card of the Quotes list.
class QuoteItem {
  const QuoteItem({
    required this.number,
    required this.product,
    required this.customer,
    required this.city,
    required this.total,
    required this.validUntil,
    required this.note,
    this.status = QuoteStatus.sent,
  });

  final String number;
  final String product;
  final String customer;
  final String city;
  final double total;
  final String validUntil;
  final String note;
  final QuoteStatus status;

  QuoteItem copyWith({QuoteStatus? status}) => QuoteItem(
        number: number,
        product: product,
        customer: customer,
        city: city,
        total: total,
        validUntil: validUntil,
        note: note,
        status: status ?? this.status,
      );
}

// ---------------- Order detail ----------------

class CustomSpec {
  const CustomSpec({
    required this.dimensions,
    required this.dimensionsNote,
    required this.cutAngle,
    required this.cutNote,
    required this.thickness,
    required this.notes,
    required this.facility,
    required this.progress,
  });

  final String dimensions;
  final String dimensionsNote;
  final String cutAngle;
  final String cutNote;
  final String thickness;
  final String notes;
  final String facility;
  final String progress;
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.details,
    required this.price,
    required this.icon,
    this.qty = 1,
  });

  final String name;
  final String details;
  final double price;
  final IconData icon;
  final int qty;

  OrderLine copyWith({int? qty}) => OrderLine(
        name: name,
        details: details,
        price: price,
        icon: icon,
        qty: qty ?? this.qty,
      );
}

class PaymentRecord {
  const PaymentRecord({
    required this.method,
    required this.dateLabel,
    required this.kind,
    required this.amount,
    required this.icon,
    this.statusLabel = 'Authorized',
  });

  final String method;
  final String dateLabel;

  /// Deposit, Partial payment, Final balance.
  final String kind;
  final double amount;
  final IconData icon;
  final String statusLabel;
}

class TimelineEvent {
  const TimelineEvent({
    required this.title,
    required this.time,
    required this.by,
    this.done = true,
  });

  final String title;
  final String time;
  final String by;
  final bool done;
}

class OrderDetail {
  const OrderDetail({
    required this.number,
    required this.customer,
    required this.store,
    required this.placed,
    required this.status,
    required this.spec,
    required this.lines,
    required this.taxRate,
    required this.payments,
    required this.destination,
    required this.destinationNote,
    required this.deliveryWindow,
    required this.deliveryTeam,
    required this.timeline,
  });

  final String number;
  final String customer;
  final String store;
  final String placed;
  final OrderStatus status;
  final CustomSpec? spec;
  final List<OrderLine> lines;
  final double taxRate;
  final List<PaymentRecord> payments;
  final String destination;
  final String destinationNote;
  final String deliveryWindow;
  final String deliveryTeam;
  final List<TimelineEvent> timeline;
}
