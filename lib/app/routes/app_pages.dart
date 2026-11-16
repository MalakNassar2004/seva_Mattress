import 'package:get/get.dart';
import '../../modules/auth/auth_binding.dart';
import '../../modules/auth/forgot_password_view.dart';
import '../../modules/auth/login_view.dart';
import '../../modules/auth/pin_view.dart';
import '../../modules/customers/customer_detail_view.dart';
import '../../modules/customers/customers_binding.dart';
import '../../modules/customers/customers_view.dart';
import '../../modules/deliveries/deliveries_binding.dart';
import '../../modules/deliveries/deliveries_view.dart';
import '../../modules/deliveries/delivery_detail_view.dart';
import '../../modules/orders/order_detail_view.dart';
import '../../modules/orders/order_form_view.dart';
import '../../modules/orders/orders_binding.dart';
import '../../modules/owner_shell/owner_shell_binding.dart';
import '../../modules/owner_shell/owner_shell_view.dart';
import '../../modules/product_form/product_form_binding.dart';
import '../../modules/product_form/product_form_view.dart';
import '../../modules/products/products_binding.dart';
import '../../modules/products/products_view.dart';
import '../../modules/purchase_orders/po_form_view.dart';
import '../../modules/purchase_orders/purchase_orders_binding.dart';
import '../../modules/purchase_orders/purchase_orders_view.dart';
import '../../modules/suppliers/supplier_detail_view.dart';
import '../../modules/suppliers/supplier_form_view.dart';
import '../../modules/suppliers/suppliers_binding.dart';
import '../../modules/suppliers/suppliers_view.dart';
import '../../modules/staff/permissions_view.dart';
import '../../modules/staff/staff_binding.dart';
import '../../modules/staff/staff_form_view.dart';
import '../../modules/staff/staff_view.dart';
import '../../modules/splash/splash_binding.dart';
import '../../modules/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const Transition _transition = Transition.cupertino;

  static final List<GetPage> pages = [
    // ---------------- Auth ----------------
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.pin,
      page: () => const PinView(),
      binding: PinBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
      transition: _transition,
    ),

    // ---------------- Owner shell ----------------
    // The binding also registers the controllers of the pages shown as
    // tabs (Inventory & Stock).
    GetPage(
      name: AppRoutes.owner,
      page: () => const OwnerShellView(),
      binding: OwnerShellBinding(),
      transition: _transition,
    ),

    // ---------------- Inventory ----------------
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsView(),
      binding: ProductsBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.productAdd,
      page: () => const ProductFormView(),
      binding: ProductFormBinding(isEdit: false),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.productEdit,
      page: () => const ProductFormView(),
      binding: ProductFormBinding(isEdit: true),
      transition: _transition,
    ),

    // ---------------- Customers ----------------
    GetPage(
      name: AppRoutes.customers,
      page: () => const CustomersView(),
      binding: CustomersBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.customerDetail,
      page: () => const CustomerDetailView(),
      binding: CustomerDetailBinding(),
      transition: _transition,
    ),

    // ---------------- Orders & Quotes ----------------
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailView(),
      binding: OrderDetailBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.orderForm,
      page: () => const OrderFormView(),
      binding: OrderFormBinding(),
      transition: _transition,
    ),

    // ---------------- Deliveries ----------------
    GetPage(
      name: AppRoutes.deliveries,
      page: () => const DeliveriesView(),
      binding: DeliveriesBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.deliveryDetail,
      page: () => const DeliveryDetailView(),
      binding: DeliveryDetailBinding(),
      transition: _transition,
    ),

    // ---------------- Suppliers ----------------
    GetPage(
      name: AppRoutes.suppliers,
      page: () => const SuppliersView(),
      binding: SuppliersBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.supplierDetail,
      page: () => const SupplierDetailView(),
      binding: SupplierDetailBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.supplierForm,
      page: () => const SupplierFormView(),
      binding: SupplierFormBinding(),
      transition: _transition,
    ),

    // ---------------- Purchase Orders ----------------
    GetPage(
      name: AppRoutes.purchaseOrders,
      page: () => const PurchaseOrdersView(),
      binding: PurchaseOrdersBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.poForm,
      page: () => const PoFormView(),
      binding: PoFormBinding(),
      transition: _transition,
    ),

    // ---------------- Staff ----------------
    GetPage(
      name: AppRoutes.staff,
      page: () => const StaffView(),
      binding: StaffBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.staffForm,
      page: () => const StaffFormView(),
      binding: StaffFormBinding(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.permissions,
      page: () => const PermissionsView(),
      binding: PermissionsBinding(),
      transition: _transition,
    ),
  ];
}
