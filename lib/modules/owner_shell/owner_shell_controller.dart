import 'package:get/get.dart';

/// Holds the selected tab of the Owner shell.
class OwnerShellController extends GetxController {
  static const int homeTab = 0;
  static const int ordersTab = 1;
  static const int inventoryTab = 2;
  static const int reportsTab = 3;
  static const int moreTab = 4;

  // ---------------- State ----------------
  /// Opens on the tab passed as route arguments (OwnerNav.goToTab), else Home.
  final currentIndex =
      (Get.arguments is int ? Get.arguments as int : homeTab).obs;

  // ---------------- Mock data ----------------
  /// Pending approvals shown on the More tab.
  // TODO(backend): load the real pending approvals count.
  static const int moreBadge = 3;

  // ---------------- Actions ----------------
  void changeTab(int index) => currentIndex.value = index;
}
