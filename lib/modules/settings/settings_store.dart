import 'package:get/get.dart';

/// Approval rules enforced on the registers.
class ApprovalRules {
  const ApprovalRules({
    required this.refundLimit,
    required this.maxCashierDiscount,
    required this.priceChangeApproval,
    required this.voidApproval,
    required this.managerSelfApproval,
  });

  /// Refunds above this amount (CAD) need approval.
  final double refundLimit;

  /// Max discount % a cashier can give without approval.
  final int maxCashierDiscount;
  final bool priceChangeApproval;
  final bool voidApproval;
  final bool managerSelfApproval;

  static const defaults = ApprovalRules(
    refundLimit: 150,
    maxCashierDiscount: 10,
    priceChangeApproval: true,
    voidApproval: true,
    managerSelfApproval: false,
  );

  /// Number of policies currently enforced (limits always count).
  int get activeCount =>
      2 +
      (priceChangeApproval ? 1 : 0) +
      (voidApproval ? 1 : 0) +
      (managerSelfApproval ? 1 : 0);
}

/// In-memory store settings shared by Settings and its sub-screens.
/// TODO(backend): load and save settings through the API.
class SettingsStore extends GetxService {
  static SettingsStore get to => Get.isRegistered<SettingsStore>()
      ? Get.find<SettingsStore>()
      : Get.put(SettingsStore(), permanent: true);

  // ---------------- Mock data ----------------
  static const String storeName = 'Seva Sleep Surrey Flagship';
  static const String storeAddress = '15280 104 Ave, Surrey, BC';
  static const String storePhone = '(604) 555-0100';
  static const double gst = 5;
  static const double pst = 7;
  static const int autoLockMinutes = 5;
  static const int lowStockThreshold = 2;

  final approvalRules = ApprovalRules.defaults.obs;
  final terminalOnline = true.obs;
  final lastBackup = DateTime.now().subtract(const Duration(minutes: 12)).obs;
  final lastBackupOk = true.obs;
  final backingUp = false.obs;

  Future<void> runBackup() async {
    if (backingUp.value) return;
    backingUp.value = true;
    // TODO(backend): POST /backups and wait for the job.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    lastBackup.value = DateTime.now();
    lastBackupOk.value = true;
    backingUp.value = false;
  }
}
