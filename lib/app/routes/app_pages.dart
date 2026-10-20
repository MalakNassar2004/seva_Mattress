import 'package:get/get.dart';
import '../../modules/splash/splash_view.dart';
import '../../modules/auth/login_view.dart';
import '../../modules/auth/pin_view.dart';
import '../../modules/auth/forgot_password_view.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
    ),
    GetPage(
      name: Routes.PIN,
      page: () => const PinView(),
    ),
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
    ),
  ];
}
