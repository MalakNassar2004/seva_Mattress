import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_colors_extra.dart';

enum ApprovalType { largeRefund, cancellation, priceChange, discount }

extension ApprovalTypeInfo on ApprovalType {
  String get label => switch (this) {
    ApprovalType.largeRefund => 'Large refund request',
    ApprovalType.cancellation => 'Order cancellation',
    ApprovalType.priceChange => 'Manual price change',
    ApprovalType.discount => 'Exceptional discount',
  };

  IconData get icon => switch (this) {
    ApprovalType.largeRefund => Icons.undo,
    ApprovalType.cancellation => Icons.cancel_outlined,
    ApprovalType.priceChange => Icons.sell_outlined,
    ApprovalType.discount => Icons.percent,
  };

  /// (text, background, border) of the type chip.
  (Color, Color, Color) get colors => switch (this) {
    ApprovalType.largeRefund => (
      AppColors.danger,
      AppColorsExtra.dangerSoft,
      AppColorsExtra.dangerBorder,
    ),
    ApprovalType.cancellation => (
      AppColorsExtra.amberText,
      AppColorsExtra.amberSoft,
      AppColorsExtra.amberBorder,
    ),
    ApprovalType.priceChange => (
      AppColors.textDark,
      AppColorsExtra.chipGrey,
      AppColorsExtra.panelBorder,
    ),
    ApprovalType.discount => (
      AppColors.deepBlue,
      AppColors.lightBlue,
      AppColorsExtra.infoBorder,
    ),
  };
}

enum ApprovalStatus { pending, approved, rejected }

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.type,
    required this.requester,
    required this.role,
    required this.terminal,
    required this.amount,
    required this.saleRef,
    required this.item,
    required this.reason,
    required this.time,
    this.customer,
    this.originalPrice,
    this.requestedPrice,
    this.unitCost,
    this.status = ApprovalStatus.pending,
    this.decisionNote,
    this.decidedAt,
  });

  /// "APP-4902"
  final String id;
  final ApprovalType type;
  final String requester;
  final String role;
  final String terminal;

  /// Amount at stake (refund amount, discount value, price drop).
  final double amount;

  /// "#SM-10485" or "Quote #QT-8821".
  final String saleRef;

  /// Items involved ("Seva Hybrid Luxury Queen").
  final String item;
  final String reason;
  final DateTime time;
  final String? customer;

  /// Price changes only.
  final double? originalPrice;
  final double? requestedPrice;
  final double? unitCost;

  final ApprovalStatus status;

  /// Owner note (approve) or rejection reason (reject).
  final String? decisionNote;
  final DateTime? decidedAt;

  String get initials {
    final p = requester.split(' ');
    return (p.first[0] + (p.length > 1 ? p.last[0] : '')).toUpperCase();
  }

  bool get isPriceChange =>
      originalPrice != null && requestedPrice != null && unitCost != null;

  double? get originalMargin => isPriceChange
      ? (originalPrice! - unitCost!) / originalPrice! * 100
      : null;

  double? get projectedMargin => isPriceChange
      ? (requestedPrice! - unitCost!) / requestedPrice! * 100
      : null;

  ApprovalRequest decide(ApprovalStatus s, String? note) => ApprovalRequest(
    id: id,
    type: type,
    requester: requester,
    role: role,
    terminal: terminal,
    amount: amount,
    saleRef: saleRef,
    item: item,
    reason: reason,
    time: time,
    customer: customer,
    originalPrice: originalPrice,
    requestedPrice: requestedPrice,
    unitCost: unitCost,
    status: s,
    decisionNote: note,
    decidedAt: DateTime.now(),
  );
}
