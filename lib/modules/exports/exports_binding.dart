import 'package:get/get.dart';
import 'exports_controller.dart';

class ExportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExportsController>(() => ExportsController());
  }
}
