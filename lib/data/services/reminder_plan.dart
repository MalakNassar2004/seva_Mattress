import 'package:seva_mattress/app/utils/money.dart';

/// An order, reduced to what the reminders need.
class ReminderOrder {
  const ReminderOrder({
    required this.id,
    required this.number,
    required this.customer,
    required this.city,
    required this.status,
    required this.balanceCents,
    this.nextPaymentDate,
    this.deliveryDate,
  });

  final String id;
  final String number;
  final String customer;
  final String city;

  /// The status name stored on the order ('new', 'ready', 'delivered'...).
  final String status;
  final int balanceCents;
  final DateTime? nextPaymentDate;
  final DateTime? deliveryDate;
}

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.when,
    required this.title,
    required this.body,
    required this.orderId,
  });

  final DateTime when;
  final String title;
  final String body;
  final String orderId;
}

/// Decides which reminders should exist right now. No plugin is used here, so
/// it can be tested on its own.
///
/// A payment reminder is planned 2 days and 1 day before the next payment
/// date, a delivery reminder 2 days and 1 day before the delivery date, both
/// at [hour] o'clock (local time). Reminders whose time has passed are left
/// out, and only the nearest [max] are kept (iPhone keeps 64 at most).
/// [includePayments] and [includeDeliveries] are the owner's choices in
/// Settings > Notifications.
List<PlannedReminder> planReminders(
  List<ReminderOrder> orders,
  DateTime now, {
  int hour = 9,
  int max = 60,
  bool includePayments = true,
  bool includeDeliveries = true,
}) {
  final out = <PlannedReminder>[];

  void add(
    ReminderOrder o,
    DateTime date,
    int daysBefore,
    String what,
    String body,
  ) {
    final when = DateTime(date.year, date.month, date.day - daysBefore, hour);
    if (!when.isAfter(now)) return;
    out.add(
      PlannedReminder(
        when: when,
        title: daysBefore == 1 ? '$what tomorrow' : '$what in $daysBefore days',
        body: body,
        orderId: o.id,
      ),
    );
  }

  for (final o in orders) {
    if (o.status == 'cancelled' || o.status == 'delivered') continue;

    final due = o.nextPaymentDate;
    if (includePayments && due != null && o.balanceCents > 0) {
      final body = '${o.customer} · ${o.number} · '
          '${formatCad(o.balanceCents / 100)} CAD balance';
      for (final d in const [2, 1]) {
        add(o, due, d, 'Payment due', body);
      }
    }

    final delivery = o.deliveryDate;
    if (includeDeliveries && delivery != null) {
      final body = '${o.customer} · ${o.number}'
          '${o.city.isEmpty ? '' : ' · ${o.city}'}';
      for (final d in const [2, 1]) {
        add(o, delivery, d, 'Delivery', body);
      }
    }
  }

  out.sort((a, b) => a.when.compareTo(b.when));
  return out.length > max ? out.sublist(0, max) : out;
}