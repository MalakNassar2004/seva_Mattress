import 'package:flutter/material.dart';
import '../../app/config/business_rules.dart';
import '../../app/utils/names.dart';

/// Digits of a phone number, or null when it is not a valid one (7 to 15
/// digits). Examples:
///   "(604) 555-0192"  -> 6045550192
///   "+1 604 555 0192" -> 6045550192  (same Canadian number)
///   "+20 109 746 9537" -> 201097469537
///   "0020 109 746 9537" -> 201097469537
String? normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  // International prefix 00: "0020..." -> "20...".
  if (digits.startsWith('00')) digits = digits.substring(2);
  // Canada / US: a leading country code 1 is dropped.
  if (digits.length == 11 && digits.startsWith('1')) {
    digits = digits.substring(1);
  }
  return digits.length >= 7 && digits.length <= 15 ? digits : null;
}

/// 6045550192 -> (604) 555-0192. Other numbers -> +201097469537.
String formatPhone(String digits) {
  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-'
        '${digits.substring(6)}';
  }
  return digits.isEmpty ? '' : '+$digits';
}

/// 1 -> CUST-0001, 42 -> CUST-0042, 12345 -> CUST-12345.
String customerNumberOf(int seq) => 'CUST-${seq.toString().padLeft(4, '0')}';

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
    this.number = '',
    this.phoneKey = '',
    this.email = '',
    this.address = '',
    this.notes = '',
    this.createdAt,
  });

  /// Firestore document id ('' for design mock data).
  final String id;

  /// Customer number: CUST-0001. Empty for a customer saved before numbers
  /// existed (it gets one the next time the customer is saved).
  final String number;
  final String initials;
  final String name;

  /// Phone as shown: (604) 555-0192.
  final String phone;

  /// The digits (also the unique key of the customer).
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

  /// Automatic: the total of his orders reached BusinessRules.vipThresholdCad.
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
  final orderCount = (m['orderCount'] as num?)?.toInt() ?? 0;
  final balanceCents = (m['balanceCents'] as num?)?.toInt() ?? 0;
  final totalCents = (m['totalCents'] as num?)?.toInt() ?? 0;

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
    number: (m['number'] as String?) ?? '',
    initials: initialsOf(name),
    name: name,
    phone: formatPhone(key),
    phoneKey: key,
    city: (m['city'] as String?) ?? '',
    email: email,
    address: (m['address'] as String?) ?? '',
    notes: notes,
    ordersLabel: orderCount <= 0
        ? 'No orders yet'
        : '$orderCount Order${orderCount == 1 ? '' : 's'}',
    orderCount: orderCount < 0 ? 0 : orderCount,
    balanceOwing: balanceCents > 0 ? balanceCents / 100 : null,
    // VIP is automatic. A "vip: true" typed in the console still counts.
    isVip: m['vip'] == true || totalCents >= BusinessRules.vipThresholdCents,
    note: note,
    noteIcon: noteIcon,
    createdAt: createdAt,
  );
}