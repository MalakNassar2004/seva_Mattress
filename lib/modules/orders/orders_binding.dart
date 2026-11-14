import 'package:get/get.dart';
import 'order_detail_controller.dart';
import 'order_form_controller.dart';

// OrdersController is registered by OwnerShellBinding (Orders is a tab).

class OrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderDetailController>(() => OrderDetailController());
  }
}

class OrderFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderFormController>(() => OrderFormController());
  }
}
