import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seva_mattress/data/services/auth_service.dart';

enum ResetStep { email, sent }

/// Forgot-password flow (email only):
/// 1) the employee types his email, 2) Firebase emails him a reset link.
/// The new password is chosen on the page that link opens.
class ForgotPasswordController extends GetxController {
  static const int resendSeconds = 60;

  final _authService = AuthService();

  // ---------------- State ----------------
  // The TextEditingController is intentionally NOT disposed (see the Login
  // controller note).
  final emailController = TextEditingController();

  final step = Rx<ResetStep>(ResetStep.email);
  final emailError = RxnString();
  final isSending = false.obs;
  final secondsLeft = 0.obs;

  Timer? _timer;
  String _lastSentTo = '';

  String get email => emailController.text.trim();

  // Resend countdown.
  String get timerText {
    final m = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(() => emailError.value = null);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _timer?.cancel();
    secondsLeft.value = resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft.value > 0) {
        secondsLeft.value--;
      } else {
        t.cancel();
      }
    });
  }

  /// Sends the reset email. Returns null on success, or an error message.
  /// The same success result is returned whether or not the email is
  /// registered, on purpose (nobody can discover which emails exist).
  Future<String?> _send(String value) async {
    FocusManager.instance.primaryFocus?.unfocus();
    isSending.value = true;
    final error = await _authService.sendPasswordReset(value);
    isSending.value = false;
    if (error == null) {
      _lastSentTo = value;
      _startTimer();
    }
    return error;
  }

  // ---------------- Actions ----------------
  Future<void> onSendPressed() async {
    if (isSending.value) return; // ignore double taps

    final value = email;
    if (!GetUtils.isEmail(value)) {
      emailError.value = 'Enter a valid email address';
      return;
    }
    if (value == _lastSentTo && secondsLeft.value > 0) {
      emailError.value =
      'Please wait $timerText before requesting another link.';
      return;
    }

    final error = await _send(value);
    if (error != null) {
      emailError.value = error;
      return;
    }
    step.value = ResetStep.sent;
  }

  Future<void> onResendPressed() async {
    if (secondsLeft.value > 0 || isSending.value) return;

    final error = await _send(_lastSentTo);
    Get.snackbar(
      error == null ? 'Link sent' : 'Could not send',
      error ?? 'We sent the reset link again.',
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    );
  }

  // ---------------- Navigation ----------------
  void onBackToSignInPressed() => Get.back();

  void onBackPressed() {
    switch (step.value) {
      case ResetStep.email:
        Get.back();
        break;
      case ResetStep.sent:
      // Go back to fix a typo in the email.
        step.value = ResetStep.email;
        break;
    }
  }
}