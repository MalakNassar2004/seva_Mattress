import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

enum ResetStep { contact, otp, newPassword }

enum ResetMethod { phone, google }

/// UI flow only: contact -> 4-digit code -> new password.
/// Backend wiring is marked with TODO(backend).
class ForgotPasswordController extends GetxController {
  static const int otpLength = 4;
  static const int resendSeconds = 60;
  static const int minPasswordLength = 8;

  // ---------------- State ----------------
  // The TextEditingControllers are intentionally NOT disposed (see the
  // Login controller note).
  final contactController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final step = Rx<ResetStep>(ResetStep.contact);
  final method = Rx<ResetMethod>(ResetMethod.phone);
  final contactError = RxnString();

  final otp = ''.obs;
  final secondsLeft = 0.obs;

  final newPassword = ''.obs;
  final confirmPassword = ''.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    newPasswordController.addListener(
      () => newPassword.value = newPasswordController.text,
    );
    confirmPasswordController.addListener(
      () => confirmPassword.value = confirmPasswordController.text,
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  bool get isPhone => method.value == ResetMethod.phone;
  bool get hasMinLength => newPassword.value.length >= minPasswordLength;
  bool get passwordsMatch =>
      confirmPassword.value.isNotEmpty &&
      confirmPassword.value == newPassword.value;
  bool get canReset => hasMinLength && passwordsMatch;

  // Resend countdown (UI timer kept from the design).
  String get timerText {
    final m = (secondsLeft.value ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft.value % 60).toString().padLeft(2, '0');
    return '$m:$s';
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

  // ---------------- Mock data ----------------
  // None.

  // ---------------- Actions ----------------
  // Step 1: choose method + enter contact.
  void selectMethod(ResetMethod m) {
    method.value = m;
    contactController.clear();
    contactError.value = null;
  }

  void onSendCodePressed() {
    final value = contactController.text.trim();

    if (isPhone) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 7) {
        contactError.value = 'Enter a valid phone number';
        return;
      }
    } else if (!GetUtils.isEmail(value)) {
      contactError.value = 'Enter a valid email address';
      return;
    }
    contactError.value = null;

    // TODO(backend): send a 4-digit code to the phone number / email in `value`.
    otp.value = '';
    step.value = ResetStep.otp;
    _startTimer();
  }

  // Step 2: enter the 4-digit code.
  void onNumberPressed(String number) {
    if (otp.value.length >= otpLength) return;
    otp.value += number;
  }

  void onDeletePressed() {
    if (otp.value.isEmpty) return;
    otp.value = otp.value.substring(0, otp.value.length - 1);
  }

  void onVerifyPressed() {
    if (otp.value.length < otpLength) return;
    // TODO(backend): verify the code (otp.value). Only continue when valid.
    _timer?.cancel();
    step.value = ResetStep.newPassword;
  }

  void onResendPressed() {
    if (secondsLeft.value > 0) return;
    // TODO(backend): send a new code.
    otp.value = '';
    _startTimer();
  }

  // Step 3: new password.
  void toggleObscureNew() => obscureNew.value = !obscureNew.value;
  void toggleObscureConfirm() => obscureConfirm.value = !obscureConfirm.value;

  // ---------------- Navigation ----------------
  void onResetPressed() {
    if (!canReset) return;
    // TODO(backend): send the new password (newPasswordController.text).
    Get.offAllNamed(AppRoutes.login);
  }

  void onBackPressed() {
    switch (step.value) {
      case ResetStep.contact:
        Get.back();
        break;
      case ResetStep.otp:
        _timer?.cancel();
        step.value = ResetStep.contact;
        break;
      case ResetStep.newPassword:
        step.value = ResetStep.contact;
        break;
    }
  }
}
