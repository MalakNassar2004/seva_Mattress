import 'package:get/get.dart';
import '../audit/audit_models.dart';
import '../audit/audit_store.dart';
import 'approval_models.dart';

/// In-memory approval requests shared by Approvals, Home and the More badge.
/// TODO(backend): load requests from the API and push decisions back to
/// the register that asked.
class ApprovalsStore extends GetxService {
  static ApprovalsStore get to => Get.isRegistered<ApprovalsStore>()
      ? Get.find<ApprovalsStore>()
      : Get.put(ApprovalsStore(), permanent: true);

  final requests = <ApprovalRequest>[..._mock()].obs;

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

  static List<ApprovalRequest> _mock() {
    final now = DateTime.now();
    DateTime ago(Duration d) => now.subtract(d);
    return [
      ApprovalRequest(
        id: 'APP-4902',
        type: ApprovalType.priceChange,
        requester: 'Sara Lee',
        role: 'Store Manager',
        terminal: 'Terminal #01',
        amount: 200,
        saleRef: '#SM-10485',
        item: 'Seva Hybrid Luxury Queen (60×80)',
        customer: 'David Thompson',
        originalPrice: 1899,
        requestedPrice: 1699,
        unitCost: 680,
        reason:
            'Customer showed a competitor quote for a similar hybrid at '
            '\$1,720. Matching to close the sale today.',
        time: ago(const Duration(minutes: 8)),
      ),
      ApprovalRequest(
        id: 'APP-4901',
        type: ApprovalType.largeRefund,
        requester: 'Marcus Vance',
        role: 'Senior Cashier',
        terminal: 'Terminal #02',
        amount: 2349.50,
        saleRef: '#SM-10482',
        item: 'Seva Hybrid Queen + 2x Cloud Bamboo Pillow',
        customer: 'Marcus Vance',
        reason:
            '100-night comfort guarantee return. Mattress inspected; '
            'customer requests refund to original Visa.',
        time: ago(const Duration(minutes: 34)),
      ),
      ApprovalRequest(
        id: 'APP-4900',
        type: ApprovalType.discount,
        requester: 'Priya Shah',
        role: 'Assistant Manager',
        terminal: 'Terminal #03',
        amount: 420,
        saleRef: 'Quote #QT-8821',
        item: '2x Cloud Rest Latex King + Foundation',
        customer: 'Elena Rostova',
        reason:
            'Multi-room developer bulk purchase; discount beyond the '
            'standard 10% ceiling (15% total).',
        time: ago(const Duration(hours: 1)),
      ),
      ApprovalRequest(
        id: 'APP-4897',
        type: ApprovalType.cancellation,
        requester: 'Daniel Kim',
        role: 'Cashier',
        terminal: 'Register 1',
        amount: 758,
        saleRef: '#SM-10466',
        item: 'Organic Wool Mattress Topper',
        reason: 'Customer cancelled before delivery; topper still sealed.',
        time: ago(const Duration(days: 1, hours: 2)),
        status: ApprovalStatus.approved,
        decisionNote: 'OK — restock and refund deposit.',
        decidedAt: ago(const Duration(days: 1)),
      ),
      ApprovalRequest(
        id: 'APP-4893',
        type: ApprovalType.discount,
        requester: 'Liam Bennett',
        role: 'Cashier',
        terminal: 'Register 2',
        amount: 380,
        saleRef: '#SM-10451',
        item: 'Cloud Rest Latex King',
        reason: 'Friend of staff discount.',
        time: ago(const Duration(days: 3)),
        status: ApprovalStatus.rejected,
        decisionNote: 'Not covered by the staff discount policy.',
        decidedAt: ago(const Duration(days: 3)),
      ),
    ];
  }
}
