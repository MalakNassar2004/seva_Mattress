import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../staff/permissions_controller.dart';
import '../staff/pick_staff_sheet.dart';
import '../staff/staff_store.dart';

/// More tab (owner menu). Lives inside the owner shell, so its controller
/// is registered by OwnerShellBinding.
/// UI state only. Backend wiring is marked with TODO(backend).
class MoreController extends GetxController {
  final staffStore = StaffStore.to;

  // ---------------- Mock data ----------------
  // TODO(backend): load the signed-in owner profile.
  static const String ownerInitials = 'OW';
  static const String storeName = 'Surrey Flagship Showroom';
  static const String storeAddress = '15280 104 Ave, Surrey, BC';
  static const String ownerPin = '#OWN-001';

  int get staffCount => staffStore.staff.where((s) => s.active).length;
  int get onShiftCount => staffStore.staff.where((s) => s.onShift).length;

  // ---------------- Navigation ----------------
  void onCustomers() => Get.toNamed(AppRoutes.customers);
  void onSuppliers() => Get.toNamed(AppRoutes.suppliers);
  void onPurchaseOrders() => Get.toNamed(AppRoutes.purchaseOrders);
  void onDeliveries() => Get.toNamed(AppRoutes.deliveries);
  void onStaff() => Get.toNamed(AppRoutes.staff);
  void onExports() => Get.toNamed(AppRoutes.exports);
  void onAuditLog() => Get.toNamed(AppRoutes.auditLog);
  void onSettings() => Get.toNamed(AppRoutes.settings);

  Future<void> onPermissions() async {
    final m = await PickStaffSheet.open();
    if (m == null) return;
    Get.toNamed(AppRoutes.permissions, arguments: PermissionsArgs(m));
  }

  void onApprovals() {
    // TODO(design): the Approvals queue screen is not designed yet.
    showDarkToast('Approvals queue is coming soon', trailing: '', info: true);
  }

  /// Locks the app and asks for a PIN (another employee can sign in).
  void onSwitchUser() => Get.offAllNamed(AppRoutes.pin);

  Future<void> onSignOut() async {
    final ok = await showConfirmSheet(
      title: 'Sign out?',
      message:
          'This ends the owner session on this device. You will need '
          'your email and password to sign in again.',
      confirmLabel: 'Sign out',
      icon: Icons.logout,
      danger: true,
    );
    if (!ok) return;
    // TODO(backend): revoke the session token.
    Get.offAllNamed(AppRoutes.login);
  }
}
