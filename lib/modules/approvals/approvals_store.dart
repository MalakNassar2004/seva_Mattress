import 'package:get/get.dart';
import '../audit/audit_models.dart';
import '../audit/audit_store.dart';
import 'approval_models.dart';

/// Approval requests shared by Approvals, Home and the More badge.
///
/// The list starts EMPTY: approval requests are created by the cashier and
/// manager screens, which are not built yet. The 5 demo requests were removed
/// so nothing fake shows as real.
/// TODO(backend): load requests from Firestore when they can be created.
class ApprovalsStore extends GetxService {
  static ApprovalsStore get to => Get.isRegistered<ApprovalsStore>()
      ? Get.find<ApprovalsStore>()
      : Get.put(ApprovalsStore(), permanent: true);

  final requests = <ApprovalRequest>[].obs;

  int get pendingCount =>
      requests.where((r) => r.status == ApprovalStatus.pending).length;

  List<ApprovalRequest> withStatus(ApprovalStatus s) =>
      requests.where((r) => r.status == s).toList()
        ..sort((a, b) => b.time.compareTo(a.time));

  ApprovalRequest? byId(String id) =>
      requests.firstWhereOrNull((r) => r.id == id);

  void decide(ApprovalRequest r, ApprovalStatus status, String? note) {
    final i = requests.indexWhere((x) => x.id == r.id);
    if (i < 0) return;
    requests[i] = r.decide(status, note);
    AuditStore.to.record(
      action: AuditAction.approval,
      sentence:
          '${status == ApprovalStatus.approved ? 'Approved' : 'Rejected'}'
          ' ${r.type.label.toLowerCase()} from ${r.requester} (${r.saleRef})',
      newValue: note?.isNotEmpty == true ? note : null,
    );
  }
}