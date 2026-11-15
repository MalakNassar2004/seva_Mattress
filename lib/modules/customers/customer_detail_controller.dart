import 'package:get/get.dart';
import 'customers_mock.dart';

/// Customer detail (owner view).
/// UI state only. Backend wiring is marked with TODO(backend).
class CustomerDetailController extends GetxController {
  // ---------------- State ----------------
  /// 0 = Orders, 1 = Notes, 2 = Warranty & Care
  final tabIndex = 2.obs;
  final hideAmounts = false.obs;

  // ---------------- Mock data ----------------
  // TODO(backend): load the selected customer instead of these mock values.
  static const String name = CustomerDetailMock.name;
  static const String customerId = CustomerDetailMock.customerId;
  static const String phone = CustomerDetailMock.phone;
  static const String email = CustomerDetailMock.email;
  static const List<String> tabLabels = CustomerDetailMock.tabLabels;

  // ---------------- Actions ----------------
  void selectTab(int i) => tabIndex.value = i;

  void toggleAmounts() => hideAmounts.value = !hideAmounts.value;

  void onEditPressed() {
    // TODO(backend): open the Edit Customer form (bottom sheet) and save.
  }

  void onMorePressed() {
    // TODO(backend): open the customer actions menu.
  }

  void onCallPressed() {
    // TODO(backend): open the phone dialer with `phone`.
  }

  void onSmsPressed() {
    // TODO(backend): open SMS with `phone`.
  }

  void onEmailPressed() {
    // TODO(backend): open the mail app with `email`.
  }

  void onAddAddressPressed() {
    // TODO(backend): open the Add Address form (not designed yet) and save.
  }

  void onCreateOrderPressed() {
    // TODO(backend): open the new order / quote flow for this customer.
  }

  void onLogNotePressed() {
    // TODO(backend): open the After-Sales Note form (not designed yet) and save.
  }

  // ---------------- Navigation ----------------
  void onBackPressed() => Get.back();
}
