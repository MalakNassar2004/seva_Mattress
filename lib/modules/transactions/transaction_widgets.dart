import 'package:flutter/material.dart';
import '../../app/widgets/owner_widgets.dart';
import '../sales/sales_models.dart';

/// Colored status chip ("● Paid", "● Refunded").
class SaleStatusChip extends StatelessWidget {
  const SaleStatusChip(this.status, {super.key, this.fontSize = 11});

  final SaleStatus status;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, border) = status.colors;
    return StatusPill(
      text: status.label,
      dot: true,
      fg: fg,
      bg: bg,
      border: border,
      fontSize: fontSize,
    );
  }
}
