import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/app/routes/app_routes.dart';
import 'package:seva_mattress/data/repositories/notification_prefs_repository.dart';
import 'package:seva_mattress/data/services/notification_types.dart';
import 'package:seva_mattress/data/services/reminder_plan.dart';
import 'package:seva_mattress/modules/orders/order_models.dart'
    show orderItemFromMap;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the payment and delivery reminders on THIS phone. They are
/// planned from the live orders, and re-planned whenever an order or the
/// owner's notification choices change. They fire even when the app is
/// closed. Tapping one opens the order.
///
/// The phone learns about an order only while the app is open on it, so a
/// phone that never opens the app gets no reminders. Notifications that are
/// sent from a server (delivered, cancelled, refunded...) are separate.
class ReminderService extends GetxService {
  static ReminderService get to => Get.isRegistered<ReminderService>()
      ? Get.find<ReminderService>()
      : Get.put(ReminderService(), permanent: true);

  /// TESTING ONLY. true = a test reminder fires 20 seconds after the app
  /// signs in (put the app in the background to see it), and tapping it opens
  /// the most recent order. Keep it false.
  static const bool _debugFireSoon = false;

  final _plugin = FlutterLocalNotificationsPlugin();
  final _prefs = NotificationPrefsRepository();

  bool _initialized = false;
  bool _running = false;
  bool _working = false;
  bool _again = false;

  List<ReminderOrder> _orders = const [];
  String? _pendingOrderId;
  DateTime? _debugAt;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<Set<String>>? _prefsSub;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails('reminders', 'Reminders'),
    iOS: DarwinNotificationDetails(),
  );

  // ---------------- Start / stop ----------------
  /// Call after the employee signed in.
  Future<void> start() async {
    if (_running) return;
    _running = true;

    try {
      await _init();
    } catch (e) {
      debugPrint('REMINDERS init failed: $e');
      _running = false;
      return;
    }

    _ordersSub = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .listen((snap) {
      _orders = [for (final d in snap.docs) _toReminderOrder(d.id, d.data())];
      _schedule();
    }, onError: (Object e) => debugPrint('REMINDERS orders error: $e'));

    _prefsSub = _prefs.watch().listen(
      (_) => _schedule(),
      onError: (Object e) => debugPrint('REMINDERS prefs error: $e'),
    );

    await _readLaunchTap();
    unawaited(_openPending(afterStart: true));
  }

  /// Call on sign out: nothing is scheduled any more on this phone.
  Future<void> stop() async {
    _running = false;
    await _ordersSub?.cancel();
    _ordersSub = null;
    await _prefsSub?.cancel();
    _prefsSub = null;
    _orders = const [];
    _debugAt = null;
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (_) {}
  }

  // ---------------- Plugin ----------------
  Future<void> _init() async {
    if (_initialized) return;
    // On iPhone the permission is asked here, the first time.
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (r) => _onTap(r.payload),
    );
    _initialized = true;
  }

  /// The app was closed and a notification opened it.
  Future<void> _readLaunchTap() async {
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      if (d != null && d.didNotificationLaunchApp) {
        final p = d.notificationResponse?.payload;
        if (p != null && p.isNotEmpty) _pendingOrderId = p;
      }
    } catch (_) {}
  }

  void _onTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    _pendingOrderId = payload;
    if (_running) unawaited(_openPending());
  }

  /// Opens the order of the notification that was tapped.
  Future<void> _openPending({bool afterStart = false}) async {
    final id = _pendingOrderId;
    if (id == null) return;
    _pendingOrderId = null;

    // Right after sign-in the app is still opening the owner screen.
    if (afterStart) await Future<void>.delayed(const Duration(milliseconds: 1500));

    try {
      final snap =
          await FirebaseFirestore.instance.collection('orders').doc(id).get();
      final m = snap.data();
      if (m == null) return;
      final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      Get.toNamed(AppRoutes.orderDetail, arguments: orderItemFromMap(id, m, at));
    } catch (e) {
      debugPrint('REMINDERS could not open the order: $e');
    }
  }

  // ---------------- Planning ----------------
  ReminderOrder _toReminderOrder(String id, Map<String, dynamic> m) {
    final total = (m['totalCents'] as num?)?.toInt() ?? 0;
    final paid = (m['paidCents'] as num?)?.toInt() ?? 0;
    return ReminderOrder(
      id: id,
      number: (m['number'] as String?) ?? '',
      customer: (m['customerName'] as String?) ?? '',
      city: (m['customerCity'] as String?) ?? '',
      status: (m['status'] as String?) ?? 'new',
      balanceCents: total - paid > 0 ? total - paid : 0,
      nextPaymentDate: (m['nextPaymentDate'] as Timestamp?)?.toDate(),
      deliveryDate: (m['deliveryDate'] as Timestamp?)?.toDate(),
    );
  }

  /// A change can arrive while the plan is being rebuilt: it is rebuilt once
  /// more afterwards, never two at the same time.
  void _schedule() {
    if (!_running) return;
    if (_working) {
      _again = true;
      return;
    }
    unawaited(_run());
  }

  Future<void> _run() async {
    _working = true;
    try {
      do {
        _again = false;
        await _rebuild();
      } while (_again && _running);
    } catch (e) {
      debugPrint('REMINDERS schedule failed: $e');
    }
    _working = false;
  }

  /// The exact moment, as the plugin wants it. The phone keeps the instant,
  /// so the 9:00 AM local time stays correct.
  tz.TZDateTime _at(DateTime when) {
    final u = when.toUtc();
    return tz.TZDateTime.utc(u.year, u.month, u.day, u.hour, u.minute, u.second);
  }

  Future<void> _rebuild() async {
    await _plugin.cancelAllPendingNotifications();

    final plan = planReminders(
      _orders,
      DateTime.now(),
      includePayments: NotificationTypes.isOn('paymentReminders'),
      includeDeliveries: NotificationTypes.isOn('deliveryReminders'),
    );

    var i = 0;
    for (final r in plan) {
      await _plugin.zonedSchedule(
        id: i++,
        scheduledDate: _at(r.when),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
        payload: r.orderId,
      );
    }
    debugPrint('REMINDERS scheduled: ${plan.length}');

    if (_debugFireSoon && _orders.isNotEmpty) {
      _debugAt ??= DateTime.now().add(const Duration(seconds: 20));
      if (_debugAt!.isAfter(DateTime.now())) {
        final o = _orders.first;
        await _plugin.zonedSchedule(
          id: 9000,
          scheduledDate: _at(_debugAt!),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Test reminder',
          body: '${o.customer} · ${o.number}',
          payload: o.id,
        );
      }
    }
  }
}