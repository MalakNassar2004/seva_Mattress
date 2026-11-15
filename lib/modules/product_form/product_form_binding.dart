import 'package:get/get.dart';
import 'product_form_controller.dart';

/// Used by two routes: /product-add (isEdit: false) and /product-edit
/// (isEdit: true).
class ProductFormBinding extends Bindings {
  ProductFormBinding({required this.isEdit});

  final bool isEdit;

  @override
  void dependencies() {
    Get.lazyPut<ProductFormController>(
      () => ProductFormController(isEdit: isEdit),
    );
  }
}
