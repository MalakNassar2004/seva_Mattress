import 'package:get/get.dart';
import '../../app/utils/dates.dart';
import '../owner_shell/owner_nav.dart';
import 'audit_event_sheet.dart';
import 'audit_models.dart';
import 'audit_store.dart';

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

/// Read-only Audit Log (owner). Opened from the More tab.
/// UI state only. Backend wiring is marked with TODO(backend).
class AuditController extends GetxController {
  final store = AuditStore.to;

  // ---------------- State ----------------
  final query = ''.obs;

  /// null = all action types.
  final action = Rxn<AuditAction>();

  /// null = all users.
  final user = RxnString();
  final dateFilter = AuditDateFilter.last7Days.obs;

  // ---------------- Derived ----------------
  /// Distinct people in the log, owner first.
  List<String> get users {
    final names = store.events.map((e) => e.actor).toSet().toList()..sort();
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
    return store.events.where((e) {
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
