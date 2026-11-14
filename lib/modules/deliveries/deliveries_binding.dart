import 'package:get/get.dart';
import 'deliveries_controller.dart';
import 'delivery_detail_controller.dart';

class DeliveriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeliveriesController>(() => DeliveriesController());
  }
}

class DeliveryDetailBinding extends Bindings {
  @override
  void dependencies() {
    // The detail reads and updates the board's list, so make sure it exists
    // even when the detail is opened directly.
    if (!Get.isRegistered<DeliveriesController>()) {
      Get.lazyPut<DeliveriesController>(() => DeliveriesController());
    }
    Get.lazyPut<DeliveryDetailController>(() => DeliveryDetailController());
  }
}
