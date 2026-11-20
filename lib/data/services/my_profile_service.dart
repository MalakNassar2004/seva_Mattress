import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/repositories/profile_repository.dart';

/// The name, phone and email of the signed-in employee, live. The More tab
/// shows them, and they refresh as soon as the profile is saved.
class MyProfileService extends GetxService {
  static MyProfileService get to => Get.isRegistered<MyProfileService>()
      ? Get.find<MyProfileService>()
      : Get.put(MyProfileService(), permanent: true);

  final name = ''.obs;
  final phone = ''.obs;
  final email = ''.obs;

  final _repo = ProfileRepository();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<Map<String, dynamic>?>? _docSub;
  String? _uid;

  @override
  void onInit() {
    super.onInit();
    _authSub = FirebaseAuth.instance.userChanges().listen((u) {
      email.value = u?.email ?? '';
      if (u?.uid == _uid) return;

      // Another employee signed in (or nobody): follow his document.
      _uid = u?.uid;
      _docSub?.cancel();
      _docSub = null;
      if (u == null) {
        name.value = '';
        phone.value = '';
        return;
      }
      _docSub = _repo.watchDoc(u.uid).listen(
        (m) {
          name.value = ((m?['name'] as String?) ?? '').trim();
          phone.value = (m?['phone'] as String?) ?? '';
        },
        onError: (Object _) {},
      );
    });
    _repo.syncEmail();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _docSub?.cancel();
    super.onClose();
  }
}