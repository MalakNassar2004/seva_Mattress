import 'package:get/get.dart';
import '../../app/utils/dates.dart';
import 'staff_mock.dart';
import 'staff_models.dart';

/// In-memory employees shared by Staff, Add / Edit Staff and the
/// Permissions Manager, so a change on one screen shows on the others.
/// TODO(backend): replace with a repository backed by the API.
class StaffStore extends GetxService {
  static StaffStore get to => Get.isRegistered<StaffStore>()
      ? Get.find<StaffStore>()
      : Get.put(StaffStore(), permanent: true);

  final staff = <StaffMember>[...StaffMock.staff].obs;

  StaffMember? byId(String id) => staff.firstWhereOrNull((s) => s.id == id);

  void save(StaffMember m) {
    final i = staff.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      staff[i] = m;
    } else {
      staff.insert(0, m);
    }
  }

  /// TODO(backend): deactivating must also revoke every session and token.
  void setActive(String id, bool active) {
    final m = byId(id);
    if (m == null) return;
    save(
      m.copyWith(
        active: active,
        lastActive: active ? 'Just now' : m.lastActive,
        deactivatedOn: active ? null : _today(),
      ),
    );
  }

  String nextId() {
    var max = 0;
    for (final s in staff) {
      final n = int.tryParse(s.id.split('-').last) ?? 0;
      if (n > max) max = n;
    }
    return 'EMP-${(max + 1).toString().padLeft(4, '0')}';
  }

  static String _today() => formatDate(DateTime.now());
}
