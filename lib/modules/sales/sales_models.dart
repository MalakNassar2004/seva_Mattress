import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';

const double gstRate = 0.05;
const double pstRate = 0.07;

enum SaleStatus { paid, deposit, refunded, voided }

extension SaleStatusInfo on SaleStatus {
  String get label => switch (this) {
    SaleStatus.paid => 'Paid',
    SaleStatus.deposit => 'Deposit',
    SaleStatus.refunded => 'Refunded',
    SaleStatus.voided => 'Voided',
  };

  /// (text, background, border)
  (Color, Color, Color) get colors => switch (this) {
    SaleStatus.paid => (
      AppColors.success,
      AppColorsExtra.successSoft,
      AppColorsExtra.successBorder,
    ),
    SaleStatus.deposit => (
      AppColorsExtra.amberText,
      AppColorsExtra.amberSoft,
      AppColorsExtra.amberBorder,
    ),
    SaleStatus.refunded => (
      AppColors.danger,
      AppColorsExtra.dangerSoft,
      AppColorsExtra.dangerBorder,
    ),
    SaleStatus.voided => (
      AppColors.grey,
      AppColorsExtra.chipGrey,
      AppColorsExtra.panelBorder,
    ),
  };
}

enum ProductType { mattress, pillow, protector, accessory, customSize }

extension ProductTypeInfo on ProductType {
  String get label => switch (this) {
    ProductType.mattress => 'Mattress',
    ProductType.pillow => 'Pillow',
    ProductType.protector => 'Protector',
    ProductType.accessory => 'Accessory',
    ProductType.customSize => 'Custom-size',
  };

  IconData get icon => switch (this) {
    ProductType.mattress => Icons.bed_outlined,
    ProductType.pillow => Icons.cloud_outlined,
    ProductType.protector => Icons.shield_outlined,
    ProductType.accessory => Icons.category_outlined,
    ProductType.customSize => Icons.straighten,
  };
}

enum PayMethod { card, cash, other }

extension PayMethodInfo on PayMethod {
  String get label => switch (this) {
    PayMethod.card => 'Card',
    PayMethod.cash => 'Cash',
    PayMethod.other => 'Other',
  };

  IconData get icon => switch (this) {
    PayMethod.card => Icons.credit_card,
    PayMethod.cash => Icons.payments_outlined,
    PayMethod.other => Icons.account_balance_wallet_outlined,
  };

  /// Segment color in the stacked payment bar.
  Color get color => switch (this) {
    PayMethod.card => AppColors.primaryBlue,
    PayMethod.cash => const Color(0xFF38BDF8),
    PayMethod.other => AppColors.greyLight,
  };
}

class SaleLine {
  const SaleLine({
    required this.name,
    required this.size,
    required this.qty,
    required this.price,
    required this.cost,
    required this.type,
  });

  final String name;
  final String size;
  final int qty;

  /// Unit selling price (CAD, before tax).
  final double price;

  /// Unit cost (owner-only).
  final double cost;
  final ProductType type;

  double get total => price * qty;
  double get costTotal => cost * qty;
  double get marginPct => price == 0 ? 0 : (price - cost) / price * 100;
}

class SalePayment {
  const SalePayment({
    required this.method,
    required this.label,
    required this.reference,
    required this.amount,
  });

  final PayMethod method;

  /// "Visa •••• 4892", "Interac Debit", "Cash".
  final String label;
  final String reference;
  final double amount;
}

/// One step of the transaction timeline.
class SaleEvent {
  const SaleEvent(this.label, this.by, this.time, {this.icon = Icons.circle});

  final String label;
  final String by;
  final DateTime time;
  final IconData icon;
}

enum RefundState { none, pending, completed }

class Sale {
  const Sale({
    required this.invoice,
    required this.customer,
    required this.cashier,
    required this.time,
    required this.lines,
    required this.payments,
    required this.status,
    required this.timeline,
    this.discount = 0,
    this.note,
    this.refunded = 0,
    this.refundState = RefundState.none,
  });

  /// "SM-10482" (shown as "#SM-10482").
  final String invoice;
  final String customer;
  final String cashier;
  final DateTime time;
  final List<SaleLine> lines;
  final List<SalePayment> payments;
  final SaleStatus status;
  final List<SaleEvent> timeline;
  final double discount;

  /// Short context line ("Walk-in VIP", "Scheduled delivery Oct 24").
  final String? note;

  /// Amount refunded so far (CAD, incl. tax).
  final double refunded;
  final RefundState refundState;

  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
  double get subtotal => lines.fold(0, (s, l) => s + l.total);
  double get taxable => subtotal - discount;
  double get gst => taxable * gstRate;
  double get pst => taxable * pstRate;
  double get taxes => gst + pst;
  double get total => taxable + taxes;
  double get paid => payments.fold(0, (s, p) => s + p.amount);
  double get balance => (total - paid).clamp(0, double.infinity);
  double get cost => lines.fold(0, (s, l) => s + l.costTotal);

  /// Counts toward sales figures (voided sales do not).
  bool get counts => status != SaleStatus.voided;

  String get customerInitials => _initials(customer);
  String get cashierInitials => _initials(cashier);

  /// "1x Seva Hybrid Luxury Queen + 2x Cloud Bamboo Pillow"
  String get summary => lines.map((l) => '${l.qty}x ${l.name}').join(' + ');

  static String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+'));
    return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
  }

  Sale copyWith({
    SaleStatus? status,
    double? refunded,
    RefundState? refundState,
    List<SaleEvent>? timeline,
  }) => Sale(
    invoice: invoice,
    customer: customer,
    cashier: cashier,
    time: time,
    lines: lines,
    payments: payments,
    status: status ?? this.status,
    timeline: timeline ?? this.timeline,
    discount: discount,
    note: note,
    refunded: refunded ?? this.refunded,
    refundState: refundState ?? this.refundState,
  );
}
