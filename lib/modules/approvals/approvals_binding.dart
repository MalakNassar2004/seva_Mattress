import 'package:get/get.dart';
import 'approvals_controller.dart';

class ApprovalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApprovalsController>(() => ApprovalsController());
  }
}
