import 'package:get/get.dart';

/// Holds the selected tab of the Owner shell.
class OwnerShellController extends GetxController {
  static const int homeTab = 0;

  /// Pending approvals shown on the More tab.
  // TODO(backend): load the real pending approvals count.
  static const int moreBadge = 3;

  final currentIndex = homeTab.obs;

  void changeTab(int index) => currentIndex.value = index;
}
