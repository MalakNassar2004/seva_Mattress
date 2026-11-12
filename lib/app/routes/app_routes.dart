/// Named routes for the whole app. Always navigate with Get.toNamed /
/// Get.offAllNamed and these constants, never Get.to(() => ...).
abstract class AppRoutes {
  // ---------------- Auth ----------------
  static const String splash = '/splash';
  static const String login = '/login';
  static const String pin = '/pin';
  static const String forgotPassword = '/forgot-password';

  // ---------------- Owner shell ----------------
  /// Tabs: Home, Orders, Inventory, Reports, More. Pass the tab index as
  /// `arguments` to open on a specific tab (see OwnerNav.goToTab).
  static const String owner = '/owner';

  // ---------------- Inventory ----------------
  // The Inventory & Stock page itself is the Inventory tab of /owner.
  static const String products = '/products';
  static const String productAdd = '/product-add';
  static const String productEdit = '/product-edit';

  // ---------------- Customers ----------------
  static const String customers = '/customers';
  static const String customerDetail = '/customer-detail';
}
