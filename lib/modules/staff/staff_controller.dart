import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_nav.dart';
import 'deactivate_staff_sheet.dart';
import 'staff_models.dart';
import 'staff_store.dart';

enum StaffStatusFilter { active, deactivated }

/// Staff list (owner). Opened from the More tab.
/// UI state only. Backend wiring is marked with TODO(backend).
class StaffController extends GetxController {
  final store = StaffStore.to;

  // ---------------- State ----------------
  final query = ''.obs;

  /// null = All roles.
  final role = Rxn<StaffRole>();
  final status = StaffStatusFilter.active.obs;

  List<StaffMember> get _statusMatches => store.staff
      .where(
        (s) => status.value == StaffStatusFilter.active ? s.active : !s.active,
      )
      .toList();

  int get activeCount => store.staff.where((s) => s.active).length;
  int get deactivatedCount => store.staff.length - activeCount;
  int get onShiftCount => store.staff.where((s) => s.onShift).length;

  /// Count on the role chips, within the selected status.
  int countFor(StaffRole? r) =>
      _statusMatches.where((s) => r == null || s.role == r).length;

  List<StaffMember> get visible {
    final q = query.value.trim().toLowerCase();
    return _statusMatches.where((s) {
      if (role.value != null && s.role != role.value) return false;
      if (q.isEmpty) return true;
      return '${s.name} ${s.title} ${s.role.label} ${s.email} ${s.id}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  // ---------------- Actions ----------------
  void onSearchChanged(String v) => query.value = v;
  void selectRole(StaffRole? r) => role.value = r;
  void selectStatus(StaffStatusFilter s) => status.value = s;

  void onFiltersPressed() {
    // TODO(design): advanced staff filters (location, shift).
  }

  /// Switch on a row. Turning off asks for confirmation first.
  Future<void> onActiveChanged(StaffMember m, bool value) async {
    if (!value) {
      final ok = await DeactivateStaffSheet.open(m);
      if (!ok) return;
      // TODO(backend): POST /staff/{id}/deactivate (revokes all sessions).
      store.setActive(m.id, false);
      showDarkToast('${m.name} deactivated and signed out');
    } else {
      // TODO(backend): POST /staff/{id}/activate.
      store.setActive(m.id, true);
      showDarkToast('${m.name} reactivated');
    }
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  void onStaffTap(StaffMember m) =>
      Get.toNamed(AppRoutes.staffForm, arguments: m.id);

  void onAddPressed() => Get.toNamed(AppRoutes.staffForm);

  void onNavTap(int index) => OwnerNav.goToTab(index);
}
