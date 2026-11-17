import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/services/session_service.dart';
import 'package:seva_mattress/modules/auth/app_lock_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/names.dart';
import '../../app/widgets/page_widgets.dart';
import '../staff/permissions_controller.dart';
import '../staff/pick_staff_sheet.dart';
import '../staff/staff_store.dart';

/// More tab (owner menu). Lives inside the owner shell, so its controller
/// is registered by OwnerShellBinding.
class MoreController extends GetxController {
  /// The staff list is still demo data: it is only touched when the Staff
  /// tile is visible (see FeatureFlags).
  StaffStore get staffStore => StaffStore.to;

  static const String storeName = 'Seva Sleep Products Inc.';

  // ---------------- The signed-in employee ----------------
  final userName = ''.obs;
  final userEmail = ''.obs;
  final userRole = ''.obs;

  String get displayName {
    final n = userName.value.trim();
    if (n.isNotEmpty) return n;
    final e = userEmail.value;
    if (e.contains('@')) return e.split('@').first;
    return 'Account';
  }

  String get initials => initialsOf(displayName);

  String get roleLabel =>
      userRole.value.isEmpty ? '' : userRole.value.toUpperCase();

  int get staffCount => staffStore.staff.where((s) => s.active).length;
  int get onShiftCount => staffStore.staff.where((s) => s.onShift).length;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    userEmail.value = FirebaseAuth.instance.currentUser?.email ?? '';
    try {
      final user = await SessionService().loadCurrentUser();
      if (user == null) return;
      userName.value = user.name;
      userRole.value = user.role;
      if (user.email.isNotEmpty) userEmail.value = user.email;
    } catch (_) {
      // The card still shows the email from the sign-in.
    }
  }

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

  void onApprovals() => Get.toNamed(AppRoutes.approvals);

  /// "Switch user": a REAL sign out, so another employee can sign in.
  Future<void> onSwitchUser() =>
      Get.find<AppLockController>().signOutAndExit();

  Future<void> onSignOut() async {
    final ok = await showConfirmSheet(
      title: 'Sign out?',
      message:
          'This ends your session on this device. You will need your email '
          'and password to sign in again.',
      confirmLabel: 'Sign out',
      icon: Icons.logout,
      danger: true,
    );
    if (!ok) return;
    await Get.find<AppLockController>().signOutAndExit();
  }
}