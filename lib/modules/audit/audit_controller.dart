import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/audit_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import '../../app/utils/dates.dart';
import '../owner_shell/owner_nav.dart';
import 'audit_event_sheet.dart';
import 'audit_models.dart';

enum AuditDateFilter { today, todayYesterday, last7Days, all }

extension AuditDateFilterLabel on AuditDateFilter {
  String get label => switch (this) {
    AuditDateFilter.today => 'Today',
    AuditDateFilter.todayYesterday => 'Today & Yesterday',
    AuditDateFilter.last7Days => 'Last 7 days',
    AuditDateFilter.all => 'All time',
  };

  /// Oldest day included (null = no limit).
  int? get days => switch (this) {
    AuditDateFilter.today => 0,
    AuditDateFilter.todayYesterday => 1,
    AuditDateFilter.last7Days => 6,
    AuditDateFilter.all => null,
  };
}

/// Read-only Audit Log (owner). Opened from the More tab. Live from
/// Firestore: every other screen writes its changes into the log.
class AuditController extends GetxController {
  final _repo = AuditRepository();

  // ---------------- State ----------------
  /// All the events (newest first), live from Firestore.
  final events = <AuditEvent>[].obs;
  final isLoading = true.obs;
  final loadError = RxnString();

  final query = ''.obs;

  /// null = all action types.
  final action = Rxn<AuditAction>();

  /// null = all users.
  final user = RxnString();
  final dateFilter = AuditDateFilter.last7Days.obs;

  StreamSubscription<List<AuditEvent>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _listen() {
    isLoading.value = true;
    _sub = _repo.watchEvents().listen(
      (list) {
        events.assignAll(list);
        isLoading.value = false;
        loadError.value = null;
      },
      onError: (Object e) {
        isLoading.value = false;
        loadError.value = describeCustomerError(e);
        Get.snackbar(
          'Could not load the audit log',
          'Only the owner can read it. ${describeCustomerError(e)}',
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        );
      },
    );
  }

  // ---------------- Derived ----------------
  /// Distinct people in the log, owner first.
  List<String> get users {
    final names = events.map((e) => e.actor).toSet().toList()..sort();
    if (names.remove('Owner')) names.insert(0, 'Owner');
    return names;
  }

  bool _inDate(AuditEvent e) {
    final days = dateFilter.value.days;
    if (days == null) return true;
    final age = dateOnly(DateTime.now()).difference(dateOnly(e.time)).inDays;
    return age <= days;
  }

  /// Events matching every filter except the action type (for chip counts).
  List<AuditEvent> get _base {
    final q = query.value.trim().toLowerCase();
    return events.where((e) {
      if (user.value != null && e.actor != user.value) return false;
      if (!_inDate(e)) return false;
      if (q.isEmpty) return true;
      return '${e.actor} ${e.actorRole} ${e.employeeId ?? ''} ${e.sentence} '
              '${e.oldValue ?? ''} ${e.newValue ?? ''} ${e.terminal}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  int countFor(AuditAction? a) =>
      _base.where((e) => a == null || e.action == a).length;

  /// Visible events grouped by day, newest first.
  List<(DateTime, List<AuditEvent>)> get groups {
    final list =
        _base
            .where((e) => action.value == null || e.action == action.value)
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));
    final out = <(DateTime, List<AuditEvent>)>[];
    for (final e in list) {
      final day = dateOnly(e.time);
      if (out.isEmpty || out.last.$1 != day) out.add((day, []));
      out.last.$2.add(e);
    }
    return out;
  }

  // ---------------- Actions ----------------
  void onSearchChanged(String v) => query.value = v;
  void selectAction(AuditAction? a) => action.value = a;
  void selectUser(String? u) => user.value = u;
  void selectDate(AuditDateFilter f) => dateFilter.value = f;

  void onFiltersPressed() {
    // TODO(design): advanced filters (terminal, amount range).
  }

  void onEventTap(AuditEvent e) => AuditEventSheet.open(e);

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();
  void onNavTap(int index) => OwnerNav.goToTab(index);
}