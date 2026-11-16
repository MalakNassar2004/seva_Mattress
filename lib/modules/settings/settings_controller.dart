import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_nav.dart';
import 'settings_store.dart';

/// Settings main screen (owner). Opened from the More tab.
/// UI state only. Backend wiring is marked with TODO(backend).
class SettingsController extends GetxController {
  final store = SettingsStore.to;

  // ---------------- Actions ----------------
  Future<void> onRunBackup() async {
    await store.runBackup();
    showDarkToast('Backup completed');
  }

  // ---------------- Navigation ----------------
  void onApprovalRulesPressed() => Get.toNamed(AppRoutes.approvalRules);

  /// Sub-screens that are not designed yet.
  // TODO(design): Store profile, Taxes, Payment methods, Receipts,
  // Security and Notifications sub-screens.
  void onNotDesigned(String name) =>
      showDarkToast('$name settings are coming soon', trailing: '', info: true);

  void onBackPressed() => Get.back();
  void onNavTap(int index) => OwnerNav.goToTab(index);
}
