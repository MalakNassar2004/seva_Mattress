import 'package:get/get.dart';
import 'supplier_detail_controller.dart';
import 'supplier_form_controller.dart';
import 'suppliers_controller.dart';

class SuppliersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuppliersController>(() => SuppliersController());
  }
}

class SupplierDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupplierDetailController>(() => SupplierDetailController());
  }
}

class SupplierFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupplierFormController>(() => SupplierFormController());
  }
}
