import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../owner_shell/owner_nav.dart';
import 'customer_models.dart';
import 'customers_mock.dart';

/// Customers list (opened from the More tab).
/// UI state only. Backend wiring is marked with TODO(backend).
class CustomersController extends GetxController {
  // ---------------- State ----------------
  /// Index 1 is drawn as the amber "balance owing" chip.
  static const List<String> filters = [
    'All',
    'Balance Owing',
    'VIP',
    'Recent',
    'Sleep Trial',
  ];

  final filterIndex = 0.obs;

  // ---------------- Mock data ----------------
  // TODO(backend): load the customers and the total from the API.
  static const int totalClients = CustomersMock.totalClients;

  final customers = <CustomerItem>[...CustomersMock.customers].obs;

  // ---------------- Actions ----------------
  void selectFilter(int i) {
    filterIndex.value = i;
    // TODO(backend): filter the customers list.
  }

  void onSearchChanged(String query) {
    // TODO(backend): search by name, phone, email or postal code.
  }

  void onScanPressed() {
    // TODO(backend): scan a receipt / loyalty card and open that customer.
  }

  void onSyncPressed() {
    // TODO(backend): sync the customers list.
  }

  void onAddCustomerPressed() {
    // TODO(backend): open the Add Customer form (not designed yet) and save.
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();

  // TODO(backend): pass the customer (or its id) so the detail page loads it.
  void onCustomerTap(CustomerItem customer) =>
      Get.toNamed(AppRoutes.customerDetail);

  void onNavTap(int index) => OwnerNav.goToTab(index);
}
