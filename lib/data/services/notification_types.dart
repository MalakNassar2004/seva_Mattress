/// One kind of notification that the owner can switch on or off.
class NotificationType {
  const NotificationType(
    this.id,
    this.title,
    this.helper, {
    this.needsServer = false,
  });

  final String id;
  final String title;
  final String helper;

  /// true = it can only be sent by a server (it needs the paid Firebase plan
  /// and the Apple push key), so it is not active yet.
  final bool needsServer;
}

/// The notifications of the app, and which ones are on. The owner chooses
/// them in Settings > Notifications. [enabled] holds the last list read from
/// Firestore, so the reminder service can check it.
class NotificationTypes {
  NotificationTypes._();

  /// Scheduled on each phone.
  static const List<NotificationType> reminders = [
    NotificationType(
      'paymentReminders',
      'Payment reminders',
      '2 days and 1 day before the next payment date, with the order number '
          'and the customer name.',
    ),
    NotificationType(
      'deliveryReminders',
      'Delivery reminders',
      '2 days and 1 day before the delivery date, with the order number and '
          'the customer name.',
    ),
  ];

  /// Sent right when something happens (they need a server).
  static const List<NotificationType> instant = [
    NotificationType(
      'orderDelivered',
      'Order delivered',
      'When an order is marked delivered.',
      needsServer: true,
    ),
    NotificationType(
      'orderCancelled',
      'Order cancelled',
      'When an order is cancelled.',
      needsServer: true,
    ),
    NotificationType(
      'orderRefunded',
      'Refund issued',
      'When a refund is recorded on an order.',
      needsServer: true,
    ),
    NotificationType(
      'newOrder',
      'New order',
      'When a new order is created.',
      needsServer: true,
    ),
    NotificationType(
      'paymentReceived',
      'Payment received',
      'When a payment is recorded on an order.',
      needsServer: true,
    ),
    NotificationType(
      'lowStock',
      'Low stock',
      'When a product runs low or out of stock.',
      needsServer: true,
    ),
    NotificationType(
      'deliveryFailed',
      'Delivery failed',
      'When a delivery attempt fails.',
      needsServer: true,
    ),
  ];

  static List<NotificationType> get all => [...reminders, ...instant];

  static List<String> get allIds => [for (final t in all) t.id];

  /// The ids that are on (everything is on until the owner changes it).
  static Set<String> enabled = {...allIds};

  static void apply(Iterable<String> ids) {
    final wanted = ids.toSet();
    enabled = {
      for (final t in all)
        if (wanted.contains(t.id)) t.id,
    };
  }

  static bool isOn(String id) => enabled.contains(id);
}