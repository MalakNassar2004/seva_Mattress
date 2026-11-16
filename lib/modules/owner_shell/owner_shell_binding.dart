import 'package:get/get.dart';
import '../home/home_controller.dart';
import '../inventory/inventory_controller.dart';
import '../more/more_controller.dart';
import '../orders/orders_controller.dart';
import '../reports/reports_controller.dart';
import 'owner_shell_controller.dart';

/// The tabs live inside /owner (they are not routes), so their controllers
/// are registered here together with the shell.
class OwnerShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OwnerShellController>(() => OwnerShellController());
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<InventoryController>(() => InventoryController());
    Get.lazyPut<OrdersController>(() => OrdersController(), fenix: true);
    Get.lazyPut<ReportsController>(() => ReportsController(), fenix: true);
    Get.lazyPut<MoreController>(() => MoreController(), fenix: true);
  }
}
