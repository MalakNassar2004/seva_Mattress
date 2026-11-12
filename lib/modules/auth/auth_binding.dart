import 'package:get/get.dart';
import 'forgot_password_controller.dart';
import 'login_controller.dart';
import 'pin_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}

class PinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PinController>(() => PinController());
  }
}

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
  }
}
