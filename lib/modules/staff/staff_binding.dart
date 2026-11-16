import 'package:get/get.dart';
import 'permissions_controller.dart';
import 'staff_controller.dart';
import 'staff_form_controller.dart';

class StaffBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffController>(() => StaffController());
  }
}

class StaffFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StaffFormController>(() => StaffFormController());
  }
}

class PermissionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PermissionsController>(() => PermissionsController());
  }
}
