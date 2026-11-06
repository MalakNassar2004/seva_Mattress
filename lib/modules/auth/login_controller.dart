import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';

/// UI state only. Backend wiring is marked with TODO(backend).
class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final obscurePassword = true.obs;
  final hasEmail = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() {
      hasEmail.value = emailController.text.isNotEmpty;
    });
  }

  void toggleObscure() => obscurePassword.value = !obscurePassword.value;

  void clearEmail() => emailController.clear();

  void onLoginPressed() {
    // TODO(backend): call the sign-in API with
    // emailController.text and passwordController.text
    // TEMPORARY (design preview): always open the PIN screen.
    Get.toNamed(AppRoutes.pin);
  }

  void onForgotPasswordPressed() {
    Get.toNamed(AppRoutes.forgotPassword);
  }

  void onGoogleLoginPressed() {
    // TODO(backend): Google sign-in
  }

  void onFaceIdPressed() {
    // TODO(backend): Face ID / biometric auth
  }

// The TextEditingControllers are intentionally NOT disposed here.
// GetX deletes this controller while the page can still be on screen
// (route transition / hot reload), and a TextField that rebuilds with a
// disposed controller throws "used after being disposed".
// They hold no native resources, so they are simply garbage collected.
}