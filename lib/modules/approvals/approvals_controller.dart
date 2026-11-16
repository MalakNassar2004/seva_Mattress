import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/money.dart';
import '../../app/widgets/page_widgets.dart';
import '../../app/widgets/shared_widgets.dart';
import '../owner_shell/owner_nav.dart';
import 'approval_detail_sheet.dart';
import 'approval_models.dart';
import 'approvals_store.dart';
import 'reject_sheet.dart';

/// Approvals & Overrides (owner). Opened from Home and the More menu.
/// UI state only. Backend wiring is marked with TODO(backend).
class ApprovalsController extends GetxController {
  final store = ApprovalsStore.to;

  static const tabs = [
    ApprovalStatus.pending,
    ApprovalStatus.approved,
    ApprovalStatus.rejected,
  ];

  // ---------------- State ----------------
  final tab = 0.obs;

  ApprovalStatus get status => tabs[tab.value];
  List<ApprovalRequest> get visible => store.withStatus(status);
  int countFor(ApprovalStatus s) => store.withStatus(s).length;

  // ---------------- Actions ----------------
  void selectTab(int i) => tab.value = i;

  Future<void> onOpen(ApprovalRequest r) async {
    final d = await ApprovalDetailSheet.open(r);
    if (d == null) return;
    if (d.approve) {
      await onApprove(r, note: d.note);
    } else {
      await onReject(r, initialReason: d.note);
    }
  }

  Future<void> onApprove(ApprovalRequest r, {String? note}) async {
    final ok = await showConfirmSheet(
      title: 'Approve this request?',
      message:
          '${r.type.label} from ${r.requester} '
          '(${formatCad(r.amount)}, ${r.saleRef}). The register is unlocked '
          'right away.',
      confirmLabel: 'Approve',
      icon: Icons.check_circle_outline,
    );
    if (!ok) return;
    // TODO(backend): POST /approvals/{id}/approve.
    store.decide(r, ApprovalStatus.approved, note);
    showDarkToast('Decision recorded in the audit log');
  }

  Future<void> onReject(ApprovalRequest r, {String? initialReason}) async {
    final reason = await RejectSheet.open(r, initialReason: initialReason);
    if (reason == null) return;
    // TODO(backend): POST /approvals/{id}/reject with the reason.
    store.decide(r, ApprovalStatus.rejected, reason);
    showDarkToast('Decision recorded in the audit log');
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();
  void onNavTap(int index) => OwnerNav.goToTab(index);
}
