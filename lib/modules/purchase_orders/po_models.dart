import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';

/// Purchase order lifecycle. Drives the tabs, chips and card actions.
enum PoStatus { draft, ordered, partial, received }

extension PoStatusStyle on PoStatus {
  String get label => switch (this) {
        PoStatus.draft => 'Draft',
        PoStatus.ordered => 'Ordered',
        PoStatus.partial => 'Partially Received',
        PoStatus.received => 'Received',
      };

  Color get fg => switch (this) {
        PoStatus.draft => AppColors.grey,
        PoStatus.ordered => AppColors.primaryBlue,
        PoStatus.partial => AppColorsExtra.amberText,
        PoStatus.received => AppColors.success,
      };

  Color get bg => switch (this) {
        PoStatus.draft => AppColorsExtra.chipGrey,
        PoStatus.ordered => AppColorsExtra.infoBg,
        PoStatus.partial => AppColorsExtra.amberSoft,
        PoStatus.received => AppColorsExtra.successSoft,
      };

  Color get border => switch (this) {
        PoStatus.draft => AppColors.border,
        PoStatus.ordered => AppColorsExtra.infoBorder,
        PoStatus.partial => AppColorsExtra.amberBorder,
        PoStatus.received => AppColorsExtra.successBorder,
      };
}

/// Where the received goods are put away.
enum ReceiveLocation { warehouse, showroom, quarantine }

extension ReceiveLocationStyle on ReceiveLocation {
  String get label => switch (this) {
        ReceiveLocation.warehouse => 'Surrey Whse',
        ReceiveLocation.showroom => 'Showroom',
        ReceiveLocation.quarantine => 'Quarantine',
      };

  String get note => switch (this) {
        ReceiveLocation.warehouse => '(Default)',
        ReceiveLocation.showroom => 'Reserve',
        ReceiveLocation.quarantine => 'Damaged',
      };

  IconData get icon => switch (this) {
        ReceiveLocation.warehouse => Icons.check_circle_outline,
        ReceiveLocation.showroom => Icons.storefront_outlined,
        ReceiveLocation.quarantine => Icons.warning_amber_rounded,
      };
}

/// A product that can be ordered from a supplier (Create PO search).
class PoProduct {
  const PoProduct({
    required this.name,
    required this.sku,
    required this.sizes,
    required this.unitCost,
    required this.icon,
    this.unit = 'units',
  });

  final String name;
  final String sku;
  final List<String> sizes;
  final double unitCost;
  final IconData icon;

  /// "units", "rolls", "yards".
  final String unit;
}

/// One line of a purchase order.
class PoLine {
  const PoLine({
    required this.name,
    required this.sku,
    required this.qty,
    required this.unitCost,
    required this.icon,
    this.size = '',
    this.unit = 'units',
    this.received = 0,
    this.note = '',
  });

  final String name;
  final String sku;
  final String size;
  final int qty;
  final double unitCost;
  final IconData icon;
  final String unit;

  /// Quantity received so far (all deliveries).
  final int received;

  /// Discrepancy note written on receiving.
  final String note;

  double get total => qty * unitCost;
  int get remaining => (qty - received).clamp(0, qty);
  bool get complete => received >= qty;

  String get title => size.isEmpty ? name : '$name - $size';

  PoLine copyWith({
    int? qty,
    double? unitCost,
    String? size,
    int? received,
    String? note,
  }) =>
      PoLine(
        name: name,
        sku: sku,
        size: size ?? this.size,
        qty: qty ?? this.qty,
        unitCost: unitCost ?? this.unitCost,
        icon: icon,
        unit: unit,
        received: received ?? this.received,
        note: note ?? this.note,
      );
}

/// A purchase order.
/// TODO(backend): replace with the real PO model.
class PurchaseOrder {
  const PurchaseOrder({
    required this.number,
    required this.supplierId,
    required this.status,
    required this.lines,
    required this.expected,
    this.notes = '',
    this.lastEdited,
    this.overdue = false,
    this.freight,
    this.invoice,
    this.invoiceDue,
    this.packingSlip,
    this.carrier,
    this.dockPass,
    this.deliveryNote,
    this.receivedOn,
  });

  /// "#PO-2024-089".
  final String number;
  final String supplierId;
  final PoStatus status;
  final List<PoLine> lines;

  /// Expected delivery date.
  final DateTime expected;
  final String notes;

  /// "2 hours ago" (drafts).
  final String? lastEdited;

  /// Past the expected date and not received.
  final bool overdue;

  /// "In Transit", "In Production"...
  final String? freight;

  /// "#INV-4901" once the vendor invoiced it.
  final String? invoice;
  final String? invoiceDue;
  final String? packingSlip;
  final String? carrier;
  final String? dockPass;
  final String? deliveryNote;
  final String? receivedOn;

  double get total => lines.fold(0, (s, l) => s + l.total);
  int get itemCount => lines.length;
  int get remainingUnits => lines.fold(0, (s, l) => s + l.remaining);

  /// Value of the goods still to arrive.
  double get openValue =>
      lines.fold(0, (s, l) => s + l.remaining * l.unitCost);

  String get itemSummary => lines.map((l) => l.name).join(', ');

  bool get isOpen => status == PoStatus.ordered || status == PoStatus.partial;

  PurchaseOrder copyWith({
    PoStatus? status,
    List<PoLine>? lines,
    DateTime? expected,
    String? notes,
    String? supplierId,
    String? lastEdited,
    bool? overdue,
    String? receivedOn,
  }) =>
      PurchaseOrder(
        number: number,
        supplierId: supplierId ?? this.supplierId,
        status: status ?? this.status,
        lines: lines ?? this.lines,
        expected: expected ?? this.expected,
        notes: notes ?? this.notes,
        lastEdited: lastEdited ?? this.lastEdited,
        overdue: overdue ?? this.overdue,
        freight: freight,
        invoice: invoice,
        invoiceDue: invoiceDue,
        packingSlip: packingSlip,
        carrier: carrier,
        dockPass: dockPass,
        deliveryNote: deliveryNote,
        receivedOn: receivedOn ?? this.receivedOn,
      );
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Oct 29, 2024.
String formatPoDate(DateTime d) =>
    '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';

/// Oct 29.
String formatPoShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
