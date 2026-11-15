import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/services/app_lock_service.dart';
import 'package:seva_mattress/data/services/auth_service.dart';
import '../../app/routes/app_routes.dart';

/// Login screen logic. Firebase calls go through AuthService.
class LoginController extends GetxController {
  // ---------------- State ----------------
  // The TextEditingControllers are intentionally NOT disposed.
  // GetX deletes this controller while the page can still be on screen
  // (route transition / hot reload), and a TextField that rebuilds with a
  // disposed controller throws "used after being disposed".
  // They hold no native resources, so they are simply garbage collected.
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _authService = AuthService();
  final _appLockService = AppLockService();

  final obscurePassword = true.obs;
  final hasEmail = false.obs;
  final isLoading = false.obs;

  /// Per-field error messages (null = no error). Ready to be shown under
  /// each field if the field widget supports it.
  final emailError = RxnString();
  final passwordError = RxnString();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _autoFaceIdTried = false;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() {
      hasEmail.value = emailController.text.isNotEmpty;
      emailError.value = null;
    });
    passwordController.addListener(() {
      passwordError.value = null;
    });
  }

  @override
  void onReady() {
    super.onReady();
    _tryAutoFaceId();
  }

  /// Like a banking app: if a session is already saved on this phone, ask for
  /// Face ID right away when the login screen opens. If there is no saved
  /// session (first time, Change User, Sign out) nothing happens and the
  /// employee signs in with email/password or Google.
  Future<void> _tryAutoFaceId() async {
    if (_autoFaceIdTried) return;
    _autoFaceIdTried = true;

    if (_authService.currentUser == null) return;
    if (!await _appLockService.isAvailable()) return;

    // Let the screen appear first.
    await Future.delayed(const Duration(milliseconds: 400));
    await onFaceIdPressed();
  }

  // ---------------- Actions ----------------
  void toggleObscure() => obscurePassword.value = !obscurePassword.value;

  void clearEmail() => emailController.clear();

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Please enter your email.';
    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Please enter your password.';
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> onLoginPressed() async {
    if (isLoading.value) return; // ignore double taps

    final email = emailController.text.trim();
    final password = passwordController.text;

    final eErr = _validateEmail(email);
    final pErr = _validatePassword(password);
    emailError.value = eErr;
    passwordError.value = pErr;

    if (eErr != null) {
      _showError('Email error', eErr);
      return;
    }
    if (pErr != null) {
      _showError('Password error', pErr);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    isLoading.value = true;
    final failure = await _authService.login(email, password);
    isLoading.value = false;

    if (failure != null) {
      switch (failure.field) {
        case AuthField.email:
          emailError.value = failure.message;
          _showError('Email error', failure.message);
          break;
        case AuthField.password:
          passwordError.value = failure.message;
          _showError('Password error', failure.message);
          break;
        case AuthField.general:
          _showError('Sign in failed', failure.message);
          break;
      }
      return;
    }

    _onSignedIn();
  }

  Future<void> onGoogleLoginPressed() async {
    if (isLoading.value) return; // ignore double taps

    isLoading.value = true;
    final failure = await _authService.signInWithGoogle();
    isLoading.value = false;

    if (failure != null) {
      // Empty message = the user just closed the Google sheet: show nothing.
      if (failure.message.isNotEmpty) {
        _showError('Google sign-in', failure.message);
      }
      return;
    }

    _onSignedIn();
  }

  /// Face ID only unlocks an existing session. It never signs in by itself.
  Future<void> onFaceIdPressed() async {
    if (_authService.currentUser == null) {
      _showError('Face ID', 'Please sign in with your email and password first.');
      return;
    }

    final result = await _appLockService.authenticate();
    switch (result) {
      case UnlockResult.success:
        Get.offAllNamed(AppRoutes.pin);
        break;
      case UnlockResult.unavailable:
        _showError('Face ID', 'Face ID is not available on this device.');
        break;
      case UnlockResult.lockedOut:
        _showError('Face ID', 'Face ID is locked. Please sign in with your password.');
        break;
      case UnlockResult.failed:
        _showError('Face ID', 'Face ID did not match. Please try again.');
        break;
      case UnlockResult.canceled:
        break;
    }
  }

  // ---------------- Navigation ----------------
  /// Shared by email and Google sign-in: go to the SMS code screen.
  /// The Face ID lock is activated by the code screen after the code is
  /// verified.
  void _onSignedIn() => Get.offAllNamed(AppRoutes.pin);

  void onForgotPasswordPressed() => Get.toNamed(AppRoutes.forgotPassword);

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }
}