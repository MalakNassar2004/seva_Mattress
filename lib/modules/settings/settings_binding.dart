import 'package:get/get.dart';
import 'approval_rules_controller.dart';
import 'settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}

class ApprovalRulesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApprovalRulesController>(() => ApprovalRulesController());
  }
}
