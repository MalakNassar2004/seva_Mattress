import 'package:get/get.dart';
import '../../modules/auth/forgot_password_view.dart';
import '../../modules/auth/login_view.dart';
import '../../modules/auth/pin_view.dart';
import '../../modules/owner_shell/owner_shell_view.dart';
import '../../modules/product_form/product_form_view.dart';
import '../../modules/products/products_view.dart';
import '../../modules/splash/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const Transition _transition = Transition.cupertino;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.pin,
      page: () => const PinView(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.owner,
      page: () => const OwnerShellView(),
      transition: _transition,
    ),
    // Standalone Products page. Inside the app it is shown as the
    // Inventory tab of /owner.
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsView(),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.productAdd,
      page: () => const ProductFormView(isEdit: false),
      transition: _transition,
    ),
    GetPage(
      name: AppRoutes.productEdit,
      page: () => const ProductFormView(isEdit: true),
      transition: _transition,
    ),
  ];
}
