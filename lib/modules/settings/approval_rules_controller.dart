import 'package:get/get.dart';
import '../../app/widgets/shared_widgets.dart';
import 'settings_store.dart';

/// Approval rules sub-screen of Settings.
/// UI state only. Backend wiring is marked with TODO(backend).
class ApprovalRulesController extends GetxController {
  final store = SettingsStore.to;

  static const double refundStep = 25;
  static const double refundMax = 5000;
  static const List<num> refundPresets = [50, 150, 300, 500];
  static const List<num> discountPresets = [5, 10, 15, 20];

  late final ApprovalRules _initial = store.approvalRules.value;

  // ---------------- State ----------------
  late final refundLimit = _initial.refundLimit.obs;
  late final maxDiscount = _initial.maxCashierDiscount.obs;
  late final priceChangeApproval = _initial.priceChangeApproval.obs;
  late final voidApproval = _initial.voidApproval.obs;
  late final managerSelfApproval = _initial.managerSelfApproval.obs;

  ApprovalRules get _current => ApprovalRules(
    refundLimit: refundLimit.value,
    maxCashierDiscount: maxDiscount.value,
    priceChangeApproval: priceChangeApproval.value,
    voidApproval: voidApproval.value,
    managerSelfApproval: managerSelfApproval.value,
  );

  bool get hasChanges {
    final c = _current;
    return c.refundLimit != _initial.refundLimit ||
        c.maxCashierDiscount != _initial.maxCashierDiscount ||
        c.priceChangeApproval != _initial.priceChangeApproval ||
        c.voidApproval != _initial.voidApproval ||
        c.managerSelfApproval != _initial.managerSelfApproval;
  }

  // ---------------- Actions ----------------
  void refundMinus() =>
      refundLimit.value = (refundLimit.value - refundStep).clamp(0, refundMax);
  void refundPlus() =>
      refundLimit.value = (refundLimit.value + refundStep).clamp(0, refundMax);
  void setRefund(num v) => refundLimit.value = v.toDouble();

  void discountMinus() =>
      maxDiscount.value = (maxDiscount.value - 1).clamp(0, 100);
  void discountPlus() =>
      maxDiscount.value = (maxDiscount.value + 1).clamp(0, 100);
  void setDiscount(num v) => maxDiscount.value = v.toInt();

  void togglePriceChange(bool v) => priceChangeApproval.value = v;
  void toggleVoid(bool v) => voidApproval.value = v;
  void toggleSelfApproval(bool v) => managerSelfApproval.value = v;

  void onResetDefaults() {
    const d = ApprovalRules.defaults;
    refundLimit.value = d.refundLimit;
    maxDiscount.value = d.maxCashierDiscount;
    priceChangeApproval.value = d.priceChangeApproval;
    voidApproval.value = d.voidApproval;
    managerSelfApproval.value = d.managerSelfApproval;
  }

  void onSave() {
    // TODO(backend): PUT /settings/approval-rules (pushed to registers).
    store.approvalRules.value = _current;
    Get.back();
    showDarkToast('Approval rules saved');
  }

  void onBackPressed() => Get.back();
}
