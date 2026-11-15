import 'package:get/get.dart';
import '../inventory/inventory_controller.dart';
import '../orders/orders_controller.dart';
import 'owner_shell_controller.dart';

/// The tabs live inside /owner (they are not routes), so their controllers
/// are registered here together with the shell.
class OwnerShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OwnerShellController>(() => OwnerShellController());
    Get.lazyPut<InventoryController>(() => InventoryController());
    Get.lazyPut<OrdersController>(() => OrdersController(), fenix: true);
  }
}
