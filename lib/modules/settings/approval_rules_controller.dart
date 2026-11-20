import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/approval_rules_repository.dart';
import 'package:seva_mattress/data/repositories/customer_repository.dart'
    show describeCustomerError;
import 'package:seva_mattress/data/services/session_service.dart';
import '../../app/widgets/shared_widgets.dart';
import 'settings_store.dart';

/// Approval rules sub-screen of Settings. The rules are saved in Firestore
/// (settings/approvals), so they are the same for the whole store. Only the
/// owner can save them (the Firestore rules enforce it too).
class ApprovalRulesController extends GetxController {
  final store = SettingsStore.to;

  final _repo = ApprovalRulesRepository();

  static const double refundStep = 25;
  static const double refundMax = 5000;
  static const List<num> refundPresets = [50, 150, 300, 500];
  static const List<num> discountPresets = [5, 10, 15, 20];

  /// The rules as they are saved (what "changes" is compared with).
  late ApprovalRules _initial = store.approvalRules.value;

  // ---------------- State ----------------
  late final refundLimit = _initial.refundLimit.obs;
  late final maxDiscount = _initial.maxCashierDiscount.obs;
  late final priceChangeApproval = _initial.priceChangeApproval.obs;
  late final voidApproval = _initial.voidApproval.obs;
  late final managerSelfApproval = _initial.managerSelfApproval.obs;

  bool _saving = false;

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

  @override
  void onInit() {
    super.onInit();
    _refresh();
  }

  /// Reads the saved rules once more, so the screen never starts from old
  /// values. If the owner already changed something, it is left alone.
  Future<void> _refresh() async {
    try {
      final saved = await _repo.loadStrict();
      if (hasChanges) return;
      _initial = saved;
      _apply(saved);
    } catch (_) {
      // Not readable: the screen keeps the values it already has.
    }
  }

  void _apply(ApprovalRules r) {
    refundLimit.value = r.refundLimit;
    maxDiscount.value = r.maxCashierDiscount;
    priceChangeApproval.value = r.priceChangeApproval;
    voidApproval.value = r.voidApproval;
    managerSelfApproval.value = r.managerSelfApproval;
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

  void onResetDefaults() => _apply(ApprovalRules.defaults);

  Future<void> onSave() async {
    if (_saving) return; // ignore double taps

    var isOwner = false;
    try {
      final user = await SessionService().loadCurrentUser();
      isOwner = user?.isOwner ?? false;
    } catch (_) {
      isOwner = false;
    }
    if (!isOwner) {
      showDarkToast(
        'Only the owner can change the approval rules',
        trailing: '',
        info: true,
      );
      return;
    }

    _saving = true;
    final rules = _current;
    try {
      await _repo.save(rules);
      store.approvalRules.value = rules;
      _initial = rules;
      Get.back();
      showDarkToast('Approval rules saved');
    } catch (e) {
      showDarkToast(describeCustomerError(e), trailing: '', info: true);
    } finally {
      _saving = false;
    }
  }

  void onBackPressed() => Get.back();
}