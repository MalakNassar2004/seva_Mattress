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

  // ---------------- Orders & Quotes ----------------
  // The Orders & Quotes list itself is the Orders tab of /owner.
  /// arguments: OrderItem.
  static const String orderDetail = '/order-detail';

  /// arguments: 'order' | 'quote' (new) or a QuoteItem (edit).
  static const String orderForm = '/order-form';

  // ---------------- Deliveries ----------------
  static const String deliveries = '/deliveries';

  /// arguments: delivery id (String).
  static const String deliveryDetail = '/delivery-detail';

  // ---------------- Suppliers ----------------
  static const String suppliers = '/suppliers';

  /// arguments: supplier id (String).
  static const String supplierDetail = '/supplier-detail';

  /// arguments: supplier id (edit) or nothing (add).
  static const String supplierForm = '/supplier-form';

  // ---------------- Purchase Orders ----------------
  /// arguments: a PO number to search for (optional).
  static const String purchaseOrders = '/purchase-orders';

  /// arguments: {'supplierId': id} or {'number': draft PO number}.
  static const String poForm = '/po-form';

  // ---------------- Staff ----------------
  static const String staff = '/staff';

  /// arguments: staff id (edit) or nothing (add).
  static const String staffForm = '/staff-form';

  /// arguments: PermissionsArgs. Returns PermissionsResult when applied.
  static const String permissions = '/permissions';
}
