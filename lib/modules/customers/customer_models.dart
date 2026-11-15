import 'package:flutter/material.dart';

/// Display model for one row of the Customers list.
/// TODO(backend): replace with the real customer model.
class CustomerItem {
  const CustomerItem({
    required this.initials,
    required this.name,
    required this.phone,
    required this.city,
    required this.ordersLabel,
    required this.note,
    this.noteIcon,
    this.noteIsAccent = false,
    this.isVip = false,
    this.balanceOwing,
  });

  final String initials;
  final String name;
  final String phone;
  final String city;
  final String ordersLabel;
  final String note;
  final IconData? noteIcon;

  /// Blue note text (for example a scheduled delivery).
  final bool noteIsAccent;
  final bool isVip;

  /// null = paid in full.
  final double? balanceOwing;
}
