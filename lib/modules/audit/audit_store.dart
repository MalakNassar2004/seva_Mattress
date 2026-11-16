import 'package:get/get.dart';
import 'audit_mock.dart';
import 'audit_models.dart';

/// In-memory audit log. Other screens call [record] so their actions
/// (exports, permission changes) show up in the Audit Log.
/// TODO(backend): the real log is written server-side and is read-only.
class AuditStore extends GetxService {
  static AuditStore get to => Get.isRegistered<AuditStore>()
      ? Get.find<AuditStore>()
      : Get.put(AuditStore(), permanent: true);

  final events = <AuditEvent>[...AuditMock.events()].obs;

  /// Adds an event performed by the owner on this device.
  void record({
    required AuditAction action,
    required String sentence,
    String? oldValue,
    String? newValue,
    String? context,
  }) {
    final n = events.length + 1;
    events.insert(
      0,
      AuditEvent(
        id: 'LOC-$n',
        actor: 'Owner',
        actorRole: 'Master PIN #OWN-001',
        actorInitials: 'OWN',
        isOwner: true,
        action: action,
        sentence: sentence,
        oldValue: oldValue,
        newValue: newValue,
        time: DateTime.now(),
        context: context ?? 'Owner Mobile · This device',
        terminal: 'Owner Mobile',
        device: 'Owner phone (Seva POS app)',
        network: 'Store WiFi',
        location: 'Surrey Flagship Showroom',
        address: '15280 104 Ave, Surrey, BC',
        authorization: 'Owner PIN #OWN-001',
        hash: 'pending sync',
      ),
    );
  }
}
