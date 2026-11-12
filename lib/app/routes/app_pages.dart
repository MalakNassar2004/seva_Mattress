import 'package:get/get.dart';
import '../../modules/auth/auth_binding.dart';
import '../../modules/auth/forgot_password_view.dart';
import '../../modules/auth/login_view.dart';
import '../../modules/auth/pin_view.dart';
import '../../modules/customers/customer_detail_view.dart';
import '../../modules/customers/customers_binding.dart';
import '../../modules/customers/customers_view.dart';
import '../../modules/owner_shell/owner_shell_binding.dart';
import '../../modules/owner_shell/owner_shell_view.dart';
import '../../modules/product_form/product_form_binding.dart';
import '../../modules/product_form/product_form_view.dart';
import '../../modules/products/products_binding.dart';
import '../../modules/products/products_view.dart';
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
  ];
}
