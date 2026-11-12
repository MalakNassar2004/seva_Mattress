import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import 'owner_shell_controller.dart';

/// Switches the owner tab from anywhere. Pages that draw the owner bottom
/// navigation call this from their onNavTap.
class OwnerNav {
  OwnerNav._();

  static void goToTab(int index) {
    if (Get.isRegistered<OwnerShellController>()) {
      // The shell is already in the stack: select the tab and pop back to it.
      Get.find<OwnerShellController>().changeTab(index);
      if (Get.currentRoute != AppRoutes.owner) {
        Get.until((route) => route.settings.name == AppRoutes.owner);
      }
    } else {
      Get.offAllNamed(AppRoutes.owner, arguments: index);
    }
  }
}
