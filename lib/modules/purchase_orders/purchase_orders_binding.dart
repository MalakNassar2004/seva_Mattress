import 'package:get/get.dart';
import 'po_form_controller.dart';
import 'purchase_orders_controller.dart';

class PurchaseOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseOrdersController>(() => PurchaseOrdersController());
  }
}

class PoFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PoFormController>(() => PoFormController());
  }
}
