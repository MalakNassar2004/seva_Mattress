import 'package:flutter/material.dart';
import '../../app/utils/names.dart';

/// Digits of a 10-digit Canadian / US phone number, or null when it is not
/// one. A leading country code "1" is accepted and dropped.
String? normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('1')) {
    digits = digits.substring(1);
  }
  return digits.length == 10 ? digits : null;
}

/// 6045550192 -> (604) 555-0192
String formatPhone(String digits) {
  if (digits.length != 10) return digits;
  return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-'
      '${digits.substring(6)}';
}

/// A customer. Shown in the Customers list and on the detail page.
class CustomerItem {
  const CustomerItem({
    this.id = '',
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
    this.orderCount = 0,
    this.phoneKey = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.createdAt,
  });

  /// Firestore document id ('' for design mock data).
  final String id;
  final String initials;
  final String name;

  /// Phone as shown: (604) 555-0192.
  final String phone;

  /// The 10 digits (also the unique key of the customer).
  final String phoneKey;
  final String city;
  final String email;
  final String address;
  final String notes;
  final DateTime? createdAt;

  final String ordersLabel;
  final String note;
  final IconData? noteIcon;

  /// Blue note text (for example a scheduled delivery).
  final bool noteIsAccent;
  final bool isVip;

  /// Number of orders. The "Paid in Full" chip only shows when it is > 0.
  final int orderCount;

  /// null = paid in full.
  final double? balanceOwing;
}

/// Builds a customer from a Firestore document.
CustomerItem customerFromMap(
  String id,
  Map<String, dynamic> m, {
  DateTime? createdAt,
}) {
  final name = (m['name'] as String?) ?? '';
  final key = (m['phone'] as String?) ?? '';
  final email = (m['email'] as String?) ?? '';
  final notes = (m['notes'] as String?) ?? '';

  // The second line of the list card: the first line of the notes, or the
  // email when there are no notes.
  final firstLine = notes.trim().split('\n').first.trim();
  final String note;
  final IconData? noteIcon;
  if (firstLine.isNotEmpty) {
    note = firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine;
    noteIcon = Icons.sticky_note_2_outlined;
  } else if (email.isNotEmpty) {
    note = email;
    noteIcon = Icons.mail_outline;
  } else {
    note = '';
    noteIcon = null;
  }

  return CustomerItem(
    id: id,
    initials: initialsOf(name),
    name: name,
    phone: formatPhone(key),
    phoneKey: key,
    city: (m['city'] as String?) ?? '',
    email: email,
    address: (m['address'] as String?) ?? '',
    notes: notes,
    ordersLabel: 'No orders yet',
    note: note,
    noteIcon: noteIcon,
    createdAt: createdAt,
  );
}